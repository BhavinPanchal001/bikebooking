import { Link } from 'react-router-dom';
import { PanelCard } from '../components/PanelCard';
import { StatCard } from '../components/StatCard';
import { formatCompactNumber, formatCurrency, formatDateTime } from '../utils/format';

export function DashboardPage({ data }) {
  const queue = data.listings.filter(
    (listing) => listing.moderationStatus === 'flagged' || listing.moderationStatus === 'closed',
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
      </section>

      <section className="stats-grid">
        <StatCard
          label="Registered users"
          value={formatCompactNumber(data.metrics.totalUsers)}
          trend={`${formatCompactNumber(data.metrics.verifiedUsers)} verified`}
          tone="primary"
          helper={`${formatCompactNumber(data.metrics.incompleteUsers)} incomplete profiles`}
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
          trend={`${data.metrics.unreadChats} unread chats`}
          tone="warning"
          helper={`${data.metrics.unreadNotifications} unread notifications`}
        />
      </section>

      <section className="content-grid">
        <PanelCard
          title="Listings needing follow-up"
          subtitle="Newest listings that are flagged or closed."
        >
          <div className="list-stack">
            {queue.length > 0 ? (
              queue.slice(0, 5).map((listing) => (
                <Link key={listing.id} to={`/listings/${listing.id}`} className="list-row">
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
                </Link>
              ))
            ) : (
              <div className="empty-state">No listings currently need moderation.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Category pulse"
          subtitle="Where supply is strongest right now."
        >
          <div className="bar-stack">
            {data.categoryBreakdown.length > 0 ? (
              data.categoryBreakdown.map((item) => (
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
              ))
            ) : (
              <div className="empty-state">No category data available yet.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Top brands"
          subtitle="Most represented inventory in the marketplace."
        >
          <div className="chip-grid">
            {data.brandLeaders.length > 0 ? (
              data.brandLeaders.map((brand) => (
                <div key={brand.label} className="metric-chip">
                  <span>{brand.label}</span>
                  <strong>{brand.count} listings</strong>
                </div>
              ))
            ) : (
              <div className="empty-state">No brand distribution available yet.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Recent activity"
          subtitle="A quick feed from listings, reports, chats, and notifications."
        >
          <div className="activity-feed">
            {data.recentActivity.length > 0 ? (
              data.recentActivity.map((item) => (
                <div key={item.id} className="activity-item">
                  <span className="activity-type">{item.type}</span>
                  <div>
                    <strong>{item.title}</strong>
                    <p>{item.meta}</p>
                  </div>
                  <small>{formatDateTime(item.timestamp)}</small>
                </div>
              ))
            ) : (
              <div className="empty-state">No recent activity found in Firestore yet.</div>
            )}
          </div>
        </PanelCard>
      </section>
    </div>
  );
}
