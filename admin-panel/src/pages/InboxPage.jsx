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
            {data.conversations.map((conversation) => (
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
            ))}
          </div>
        </PanelCard>

        <PanelCard
          title="Seller reports"
          subtitle="Escalations captured from the marketplace."
        >
          <div className="list-stack">
            {data.reports.map((report) => (
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
            ))}
          </div>
        </PanelCard>
      </section>

      <PanelCard
        title="Latest seller reviews"
        subtitle="Fast quality signal from transactions and support follow-ups."
      >
        <div className="review-grid">
          {data.reviews.map((review) => (
            <article key={review.id} className="review-card">
              <div className="review-topline">
                <strong>{review.reviewerName}</strong>
                <span>{review.rating.toFixed(1)} / 5</span>
              </div>
              <p>{review.comment || 'No written feedback yet.'}</p>
              <small>{formatDateTime(review.createdAt)}</small>
            </article>
          ))}
        </div>
      </PanelCard>
    </div>
  );
}
