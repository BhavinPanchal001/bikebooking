import ReactMarkdown from 'react-markdown';

export function MarkdownPreview({
  value,
  emptyState = 'Markdown preview will appear here once content is added.',
  className = '',
}) {
  const normalized = value?.toString().trim() ?? '';

  if (!normalized) {
    return <div className={`markdown-preview markdown-preview-empty ${className}`.trim()}>{emptyState}</div>;
  }

  return (
    <div className={`markdown-preview ${className}`.trim()}>
      <ReactMarkdown>{normalized}</ReactMarkdown>
    </div>
  );
}
