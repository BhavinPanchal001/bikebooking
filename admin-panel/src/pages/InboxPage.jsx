import { PanelCard } from '../components/PanelCard';
import { formatDateTime } from '../utils/format';

export function InboxPage({ data }) {
  return (
    <div className="page-stack">
      <section className="content-grid content-grid-equal">
        <PanelCard
          title="Conversation watchlist"
          subtitle="Chats with unread bursts or suspicious activity."
        >
          <div className="list-stack">
            {data.loading ? (
              <div className="empty-state">Loading live conversations...</div>
            ) : data.conversations.length > 0 ? (
              data.conversations.map((conversation) => (
                <div key={conversation.id} className="conversation-card">
                  <div>
                    <strong>{conversation.productTitle}</strong>
                    <p>{conversation.participantNames.join(' · ')}</p>
                  </div>
                  <span className={`status-pill ${conversation.flagged ? 'status-flagged' : 'status-approved'}`}>
                    {conversation.flagged ? 'attention' : 'stable'}
                  </span>
                  <p className="conversation-preview">{conversation.lastMessage}</p>
                  <div className="conversation-meta">
                    <small>{conversation.unread} unread</small>
                    <small>{formatDateTime(conversation.updatedAt)}</small>
                  </div>
                </div>
              ))
            ) : (
              <div className="empty-state">No chat conversations are available to review.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Seller reports"
          subtitle="Escalations captured from the marketplace."
        >
          <div className="list-stack">
            {data.loading ? (
              <div className="empty-state">Loading live seller reports...</div>
            ) : data.reports.length > 0 ? (
              data.reports.map((report) => (
                <div key={report.id} className="report-card">
                  <div className="report-head">
                    <strong>{report.reason}</strong>
                    <span className={`status-pill status-${report.priority}`}>{report.priority}</span>
                  </div>
                  <p>{report.sellerName}</p>
                  <div className="conversation-meta">
                    <small>{report.status}</small>
                    <small>{formatDateTime(report.createdAt)}</small>
                  </div>
                </div>
              ))
            ) : (
              <div className="empty-state">No seller reports are currently open.</div>
            )}
          </div>
        </PanelCard>
      </section>

      <section className="content-grid content-grid-equal">
        <PanelCard
          title="Latest seller reviews"
          subtitle="Fast quality signal from transactions and support follow-ups."
        >
          <div className="review-grid">
            {data.loading ? (
              <div className="empty-state">Loading live seller reviews...</div>
            ) : data.reviews.length > 0 ? (
              data.reviews.map((review) => (
                <article key={review.id} className="review-card">
                  <div className="review-topline">
                    <strong>{review.reviewerName}</strong>
                    <span>{review.rating.toFixed(1)} / 5</span>
                  </div>
                  <p>{review.comment || 'No written feedback yet.'}</p>
                  <small>{formatDateTime(review.createdAt)}</small>
                </article>
              ))
            ) : (
              <div className="empty-state">No seller reviews are available yet.</div>
            )}
          </div>
        </PanelCard>

        <PanelCard
          title="Notification feed"
          subtitle="Latest cross-user notifications found in Firestore."
        >
          <div className="list-stack">
            {data.loading ? (
              <div className="empty-state">Loading live notifications...</div>
            ) : data.notifications.length > 0 ? (
              data.notifications.slice(0, 8).map((notification) => (
                <div key={notification.id} className="report-card">
                  <div className="report-head">
                    <strong>{notification.title}</strong>
                    <span className={`status-pill ${notification.isRead ? 'status-approved' : 'status-pending'}`}>
                      {notification.isRead ? 'read' : 'unread'}
                    </span>
                  </div>
                  <p>{notification.body || notification.type}</p>
                  <div className="conversation-meta">
                    <small>{notification.senderName || notification.recipientId}</small>
                    <small>{formatDateTime(notification.createdAt)}</small>
                  </div>
                </div>
              ))
            ) : (
              <div className="empty-state">No notifications are visible from Firestore.</div>
            )}
          </div>
        </PanelCard>
      </section>

      <PanelCard
        title="Blocked user activity"
        subtitle="Entries coming from the shared user block relationship store."
      >
        <div className="chip-grid">
          {data.loading ? (
            <div className="empty-state">Loading blocked-user activity...</div>
          ) : data.blockedUsers.length > 0 ? (
            data.blockedUsers.slice(0, 8).map((entry) => (
              <div key={entry.id} className="metric-chip">
                <span>{entry.sellerName}</span>
                <strong>{entry.blockedUserId}</strong>
                <small>{formatDateTime(entry.blockedAt)}</small>
              </div>
            ))
          ) : (
            <div className="empty-state">No blocked-user records were found.</div>
          )}
        </div>
      </PanelCard>
    </div>
  );
}
