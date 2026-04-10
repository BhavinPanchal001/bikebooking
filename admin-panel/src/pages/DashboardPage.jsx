import { PanelCard } from '../components/PanelCard';
import { StatCard } from '../components/StatCard';
import { formatCompactNumber, formatCurrency, formatDateTime } from '../utils/format';

export function DashboardPage({ data }) {
  const queue = data.listings.filter(
    (listing) => listing.moderationStatus === 'pending' || listing.moderationStatus === 'flagged',
  );

  return (
    <div className="page-stack">
      <section className="hero-card">
        <div>
          <span className="hero-kicker">Marketplace control room</span>
          <h1>Keep BikeBooking fast, trusted, and seller-friendly.</h1>
          <p>
            This admin workspace mirrors your Flutter marketplace with live-ready sections for
            listings, users, seller safety, and operational conversations.
          </p>
        </div>
        <div className="hero-aside">
          <span className="hero-aside-label">Data source</span>
          <strong>{data.source === 'firebase' ? 'Live Firebase workspace' : 'Demo workspace'}</strong>
          <p>
            {data.error ||
              'Add Firebase web credentials in `.env.local` when you are ready to connect it.'}
          </p>
        </div>
      </section>

      <section className="stats-grid">
        <StatCard
          label="Registered users"
          value={formatCompactNumber(data.metrics.totalUsers)}
          trend="+12% this week"
          tone="primary"
          helper="Profile and KYC health"
        />
        <StatCard
          label="Active listings"
          value={formatCompactNumber(data.metrics.activeListings)}
          trend={`${data.metrics.approvalQueue} waiting for review`}
          tone="accent"
          helper="Bikes, scooters, parts"
        />
        <StatCard
          label="Estimated sold value"
          value={formatCurrency(data.metrics.estimatedRevenue)}
          trend={`${data.metrics.soldListings} sold items`}
          tone="success"
          helper="Based on sold listings"
        />
        <StatCard
          label="Safety attention"
          value={formatCompactNumber(data.metrics.openReports)}
          trend={`${data.metrics.unreadChats} unread chat alerts`}
          tone="warning"
          helper="Reports and escalations"
        />
      </section>

      <section className="content-grid">
        <PanelCard
          title="Moderation queue"
          subtitle="Newest listings that need approval or follow-up."
        >
          <div className="list-stack">
            {queue.slice(0, 5).map((listing) => (
              <div key={listing.id} className="list-row">
                <div>
                  <strong>{listing.title}</strong>
                  <p>
                    {listing.sellerName} · {listing.location}
                  </p>
                </div>
                <div className="list-row-meta">
                  <span className={`status-pill status-${listing.moderationStatus}`}>
                    {listing.moderationStatus}
                  </span>
                  <small>{formatDateTime(listing.createdAt)}</small>
                </div>
              </div>
            ))}
          </div>
        </PanelCard>

        <PanelCard
          title="Category pulse"
          subtitle="Where supply is strongest right now."
        >
          <div className="bar-stack">
            {data.categoryBreakdown.map((item) => (
              <div key={item.label} className="bar-row">
                <div className="bar-label-line">
                  <span>{item.label}</span>
                  <strong>{item.count}</strong>
                </div>
                <div className="bar-track">
                  <div
                    className="bar-fill"
                    style={{ width: `${(item.count / Math.max(data.listings.length, 1)) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </PanelCard>

        <PanelCard
          title="Top brands"
          subtitle="Most represented inventory in the marketplace."
        >
          <div className="chip-grid">
            {data.brandLeaders.map((brand) => (
              <div key={brand.label} className="metric-chip">
                <span>{brand.label}</span>
                <strong>{brand.count} listings</strong>
              </div>
            ))}
          </div>
        </PanelCard>

        <PanelCard
          title="Recent activity"
          subtitle="A quick feed for ops and support."
        >
          <div className="activity-feed">
            {data.recentActivity.map((item) => (
              <div key={item.id} className="activity-item">
                <span className="activity-type">{item.type}</span>
                <div>
                  <strong>{item.title}</strong>
                  <p>{item.meta}</p>
                </div>
                <small>{formatDateTime(item.timestamp)}</small>
              </div>
            ))}
          </div>
        </PanelCard>
      </section>
    </div>
  );
}
