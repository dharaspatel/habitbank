// Supabase Edge Function: weekly-settlement
//
// Schedule with Supabase cron (e.g. every Monday 00:05 UTC):
//   select cron.schedule(
//     'weekly-settlement',
//     '5 0 * * 1',
//     $$ select net.http_post(
//          url:='https://<project>.functions.supabase.co/weekly-settlement',
//          headers:='{"Authorization":"Bearer <service-role-jwt>"}'::jsonb
//        ); $$
//   );
//
// For each group, settles the *previous* ISO week (Mon..Sun UTC):
//   - misses goal => loses `deduction_x` units
//   - winners split the loser pool equally
//   - persists a weekly_results row, updates balances
//
// Edge cases:
//   - tie splits evenly (integer floor; remainder burns)
//   - no winners => pool is burned (zero distributed)
//   - logs are read by `logged_at` between [week_start, week_end)
//   - idempotent: skipped if a weekly_results row already exists for that week.
//
// Deploy with: `supabase functions deploy weekly-settlement --no-verify-jwt`

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

type GoalType = "workouts" | "minutes";

interface Challenge {
  user_id: string;
  goal_type: GoalType;
  goal_target: number;
  deduction_x: number;
}

interface WorkoutLog {
  user_id: string;
  duration_minutes: number;
}

function previousIsoWeekUtc(now: Date): { start: Date; end: Date } {
  // ISO weeks: Monday is day 1.
  const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
  const dayOfWeek = (d.getUTCDay() + 6) % 7; // Mon=0..Sun=6
  const thisMonday = new Date(d);
  thisMonday.setUTCDate(d.getUTCDate() - dayOfWeek);
  const start = new Date(thisMonday);
  start.setUTCDate(thisMonday.getUTCDate() - 7);
  const end = new Date(thisMonday);
  return { start, end };
}

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

export function settleGroup(args: {
  challenges: Challenge[];
  logs: WorkoutLog[];
}): {
  winners: string[];
  losers: string[];
  pool: number;
  perWinner: number;
  deltas: Record<string, number>;
} {
  const totals = new Map<string, { workouts: number; minutes: number }>();
  for (const log of args.logs) {
    const t = totals.get(log.user_id) ?? { workouts: 0, minutes: 0 };
    t.workouts += 1;
    t.minutes += log.duration_minutes;
    totals.set(log.user_id, t);
  }

  const winners: string[] = [];
  const losers: string[] = [];
  let pool = 0;
  const deltas: Record<string, number> = {};

  for (const c of args.challenges) {
    const t = totals.get(c.user_id) ?? { workouts: 0, minutes: 0 };
    const score = c.goal_type === "workouts" ? t.workouts : t.minutes;
    if (score >= c.goal_target) {
      winners.push(c.user_id);
    } else {
      losers.push(c.user_id);
      pool += c.deduction_x;
      deltas[c.user_id] = (deltas[c.user_id] ?? 0) - c.deduction_x;
    }
  }

  const perWinner = winners.length > 0 ? Math.floor(pool / winners.length) : 0;
  for (const w of winners) {
    deltas[w] = (deltas[w] ?? 0) + perWinner;
  }

  return { winners, losers, pool, perWinner, deltas };
}

Deno.serve(async (_req) => {
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
  const supabase = createClient(supabaseUrl, serviceKey, {
    auth: { persistSession: false },
  });

  const { start, end } = previousIsoWeekUtc(new Date());
  const weekStart = isoDate(start);
  const weekEnd = isoDate(end);

  const { data: groups, error: groupsErr } = await supabase
    .from("groups")
    .select("id");
  if (groupsErr) {
    return new Response(JSON.stringify({ error: groupsErr.message }), {
      status: 500,
    });
  }

  const summaries: unknown[] = [];

  for (const g of groups ?? []) {
    const { data: existing } = await supabase
      .from("weekly_results")
      .select("id")
      .eq("group_id", g.id)
      .eq("week_start", weekStart)
      .maybeSingle();
    if (existing) continue;

    const { data: challenges } = await supabase
      .from("challenges")
      .select("user_id, goal_type, goal_target, deduction_x")
      .eq("group_id", g.id);
    if (!challenges || challenges.length === 0) continue;

    const { data: logs } = await supabase
      .from("workout_logs")
      .select("user_id, duration_minutes")
      .eq("group_id", g.id)
      .gte("logged_at", start.toISOString())
      .lt("logged_at", end.toISOString());

    const result = settleGroup({
      challenges: challenges as Challenge[],
      logs: (logs ?? []) as WorkoutLog[],
    });

    await supabase.from("weekly_results").insert({
      group_id: g.id,
      week_start: weekStart,
      week_end: weekEnd,
      winners: result.winners,
      losers: result.losers,
      pool_amount: result.pool,
      per_winner: result.perWinner,
    });

    for (const [userId, delta] of Object.entries(result.deltas)) {
      const { data: bal } = await supabase
        .from("balances")
        .select("balance")
        .eq("group_id", g.id)
        .eq("user_id", userId)
        .maybeSingle();
      const next = (bal?.balance ?? 0) + delta;
      await supabase.from("balances").upsert({
        group_id: g.id,
        user_id: userId,
        balance: next,
        updated_at: new Date().toISOString(),
      });
    }

    summaries.push({ group_id: g.id, ...result });
  }

  return new Response(JSON.stringify({ weekStart, weekEnd, summaries }), {
    headers: { "content-type": "application/json" },
  });
});
