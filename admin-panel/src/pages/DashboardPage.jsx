import { useMemo } from 'react';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { PanelCard } from '../components/PanelCard';
import { StatCard } from '../components/StatCard';
import { formatCompactNumber, formatCurrency } from '../utils/format';

const DAY_WINDOW = 14;
const DAY_MS = 24 * 60 * 60 * 1000;

const CHART_COLORS = {
  primary: '#10233f',
  accent: '#df6f3e',
  success: '#2f7a5c',
  warning: '#ad5b2f',
  muted: '#8a97ab',
};

const STATUS_COLORS = {
  active: CHART_COLORS.success,
  sold: CHART_COLORS.primary,
  flagged: CHART_COLORS.warning,
  pending: CHART_COLORS.accent,
  closed: CHART_COLORS.muted,
};

function startOfDay(value) {
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    return null;
  }
  date.setHours(0, 0, 0, 0);
  return date.getTime();
}

function formatDayLabel(timestamp) {
  return new Date(timestamp).toLocaleDateString(undefined, {
    day: '2-digit',
    month: 'short',
  });
}

function buildDailySeries(items, dateKey) {
  const today = startOfDay(Date.now());
  const counts = new Map();
  for (let offset = DAY_WINDOW - 1; offset >= 0; offset -= 1) {
    counts.set(today - offset * DAY_MS, 0);
  }

  for (const item of items) {
    const day = startOfDay(item?.[dateKey]);
    if (day == null || !counts.has(day)) {
      continue;
    }
    counts.set(day, counts.get(day) + 1);
  }

  return Array.from(counts.entries()).map(([timestamp, count]) => ({
    timestamp,
    label: formatDayLabel(timestamp),
    count,
  }));
}

function buildStatusBreakdown(listings) {
  const counts = new Map();
  for (const listing of listings) {
    const status = listing.moderationStatus || listing.status || 'active';
    counts.set(status, (counts.get(status) ?? 0) + 1);
  }
  return Array.from(counts.entries()).map(([label, value]) => ({
    label,
    value,
    color: STATUS_COLORS[label] ?? CHART_COLORS.muted,
  }));
}

export function DashboardPage({ data }) {
  const registrationSeries = useMemo(
    () => buildDailySeries(data.users, 'joinedAt'),
    [data.users],
  );
  const listingSeries = useMemo(
    () => buildDailySeries(data.listings, 'createdAt'),
    [data.listings],
  );
  const statusBreakdown = useMemo(
    () => buildStatusBreakdown(data.listings),
    [data.listings],
  );
  const statusTotal = statusBreakdown.reduce((sum, item) => sum + item.value, 0);

  return (
    <div className="page-stack">
      <section className="stats-grid">
        <StatCard
          label="Registered users"
          value={formatCompactNumber(data.metrics.totalUsers)}
          trend={`${formatCompactNumber(data.metrics.blockedUsers)} blocked`}
          tone="primary"
          helper="Total user accounts"
        />
        <StatCard
          label="Active listings"
          value={formatCompactNumber(data.metrics.activeListings)}
          trend={`${data.metrics.flaggedListings} flagged for review`}
          tone="accent"
          helper="Bikes, scooters, parts"
        />
        <StatCard
          label="Estimated sold value"
          value={formatCurrency(data.metrics.estimatedRevenue)}
          trend={`${data.metrics.soldListings} sold items`}
          tone="success"
          helper={`Avg active price ${formatCurrency(data.metrics.averageActivePrice)}`}
        />
        <StatCard
          label="Safety attention"
          value={formatCompactNumber(data.metrics.openReports)}
          trend={`${formatCompactNumber(data.metrics.reportedUsers)} reported persons`}
          tone="warning"
          helper={`${data.metrics.unreadChats} unread chats · ${data.metrics.unreadNotifications} unread notifications`}
        />
      </section>

      <section className="content-grid content-grid-equal">
        <PanelCard
          title="New registrations"
          subtitle={`Users joined per day — last ${DAY_WINDOW} days.`}
        >
          <div className="chart-frame">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart
                data={registrationSeries}
                margin={{ top: 8, right: 8, left: -16, bottom: 0 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(16,35,63,0.08)" vertical={false} />
                <XAxis
                  dataKey="label"
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={{ stroke: 'rgba(16,35,63,0.15)' }}
                  interval={1}
                />
                <YAxis
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                  allowDecimals={false}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(223, 111, 62, 0.08)' }}
                  contentStyle={{
                    background: '#fffaf4',
                    border: '1px solid rgba(16,35,63,0.1)',
                    borderRadius: 12,
                    fontSize: 12,
                  }}
                  formatter={(value) => [`${value} users`, 'Registered']}
                  labelFormatter={(label) => `On ${label}`}
                />
                <Bar dataKey="count" fill={CHART_COLORS.accent} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </PanelCard>

        <PanelCard
          title="New listings"
          subtitle={`Listings created per day — last ${DAY_WINDOW} days.`}
        >
          <div className="chart-frame">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart
                data={listingSeries}
                margin={{ top: 8, right: 8, left: -16, bottom: 0 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(16,35,63,0.08)" vertical={false} />
                <XAxis
                  dataKey="label"
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={{ stroke: 'rgba(16,35,63,0.15)' }}
                  interval={1}
                />
                <YAxis
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                  allowDecimals={false}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(47, 122, 92, 0.08)' }}
                  contentStyle={{
                    background: '#fffaf4',
                    border: '1px solid rgba(16,35,63,0.1)',
                    borderRadius: 12,
                    fontSize: 12,
                  }}
                  formatter={(value) => [`${value} listings`, 'Created']}
                  labelFormatter={(label) => `On ${label}`}
                />
                <Bar dataKey="count" fill={CHART_COLORS.success} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </PanelCard>
      </section>

      <section className="content-grid content-grid-equal">
        <PanelCard
          title="Listing status mix"
          subtitle="How inventory is distributed across moderation states."
        >
          <div className="chart-frame chart-frame-split">
            {statusTotal > 0 ? (
              <>
                <ResponsiveContainer width="60%" height={240}>
                  <PieChart>
                    <Pie
                      data={statusBreakdown}
                      dataKey="value"
                      nameKey="label"
                      innerRadius={55}
                      outerRadius={90}
                      paddingAngle={2}
                      stroke="none"
                    >
                      {statusBreakdown.map((entry) => (
                        <Cell key={entry.label} fill={entry.color} />
                      ))}
                    </Pie>
                    <Tooltip
                      contentStyle={{
                        background: '#fffaf4',
                        border: '1px solid rgba(16,35,63,0.1)',
                        borderRadius: 12,
                        fontSize: 12,
                      }}
                      formatter={(value, name) => [`${value} listings`, name]}
                    />
                  </PieChart>
                </ResponsiveContainer>
                <ul className="chart-legend">
                  {statusBreakdown.map((entry) => (
                    <li key={entry.label}>
                      <span className="legend-dot" style={{ background: entry.color }} />
                      <span className="legend-label">{entry.label}</span>
                      <strong>{entry.value}</strong>
                    </li>
                  ))}
                </ul>
              </>
            ) : (
              <div className="empty-state">No listings available to chart yet.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Activity volume"
          subtitle="Total items across inventory, reports, chats, and notifications."
        >
          <div className="chart-frame">
            <ResponsiveContainer width="100%" height={260}>
              <BarChart
                data={[
                  { label: 'Users', count: data.users.length },
                  { label: 'Listings', count: data.listings.length },
                  { label: 'Reports', count: data.reports.length },
                  { label: 'Chats', count: data.conversations.length },
                  { label: 'Reviews', count: data.reviews.length },
                  { label: 'Notifications', count: data.notifications.length },
                ]}
                margin={{ top: 8, right: 8, left: -16, bottom: 0 }}
              >
                <CartesianGrid strokeDasharray="3 3" stroke="rgba(16,35,63,0.08)" vertical={false} />
                <XAxis
                  dataKey="label"
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={{ stroke: 'rgba(16,35,63,0.15)' }}
                />
                <YAxis
                  tick={{ fill: CHART_COLORS.muted, fontSize: 11 }}
                  tickLine={false}
                  axisLine={false}
                  allowDecimals={false}
                />
                <Tooltip
                  cursor={{ fill: 'rgba(16, 35, 63, 0.06)' }}
                  contentStyle={{
                    background: '#fffaf4',
                    border: '1px solid rgba(16,35,63,0.1)',
                    borderRadius: 12,
                    fontSize: 12,
                  }}
                />
                <Bar dataKey="count" fill={CHART_COLORS.primary} radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </PanelCard>
      </section>
    </div >
  );
}
