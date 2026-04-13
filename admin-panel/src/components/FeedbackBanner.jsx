export function FeedbackBanner({ tone = 'neutral', children }) {
  if (!children) {
    return null;
  }

  return <div className={`feedback-banner feedback-banner-${tone}`}>{children}</div>;
}

