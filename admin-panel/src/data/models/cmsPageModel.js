import { normalizeString, toIsoString, validateRequiredText } from './masterModelUtils';

export function normalizeCmsPageSlug(value) {
  return normalizeString(value)
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s+/g, '-')
    .replace(/-+/g, '-')
    .replace(/^-|-$/g, '');
}

function normalizeMarkdown(value) {
  return value?.toString().replace(/\r\n/g, '\n').trim() ?? '';
}

function createExcerpt(bodyMarkdown) {
  return normalizeMarkdown(bodyMarkdown)
    .replace(/[#>*_`~-]/g, ' ')
    .replace(/\[(.*?)\]\((.*?)\)/g, '$1')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 180);
}

export function createCmsPageDraft(values = {}) {
  return {
    slug: normalizeCmsPageSlug(values.slug),
    title: normalizeString(values.title),
    bodyMarkdown: normalizeMarkdown(values.bodyMarkdown),
  };
}

export function validateCmsPageDraft(values = {}, { isCreate = false } = {}) {
  const errors = {};
  const slug = normalizeCmsPageSlug(values.slug);
  const titleError = validateRequiredText(values.title, 'Page title', { maxLength: 120 });
  const bodyMarkdown = normalizeMarkdown(values.bodyMarkdown);

  if (isCreate && !slug) {
    errors.slug = 'Slug is required.';
  } else if (isCreate && slug.length > 80) {
    errors.slug = 'Slug must be 80 characters or fewer.';
  }

  if (titleError) {
    errors.title = titleError;
  }

  if (!bodyMarkdown) {
    errors.bodyMarkdown = 'Markdown content is required.';
  } else if (bodyMarkdown.length > 50000) {
    errors.bodyMarkdown = 'Markdown content must be 50,000 characters or fewer.';
  }

  return errors;
}

export function cmsPageFromFirestore(snapshot) {
  const data = snapshot.data();
  const draft = createCmsPageDraft({ ...data, slug: snapshot.id });
  const version = Number.parseInt(data.version, 10) || 1;
  const publishedVersion = Number.parseInt(data.publishedVersion, 10) || 0;
  const isPublished = data.isPublished === true;

  return {
    id: snapshot.id,
    ...draft,
    version,
    publishedVersion,
    isPublished,
    hasDraftChanges: version > publishedVersion,
    publishedTitle: normalizeString(data.publishedTitle),
    publishedBodyMarkdown: normalizeMarkdown(data.publishedBodyMarkdown),
    publishedAt: toIsoString(data.publishedAt),
    publishedByEmail: normalizeString(data.publishedByEmail),
    createdAt: toIsoString(data.createdAt),
    updatedAt: toIsoString(data.updatedAt),
    previewText: createExcerpt(draft.bodyMarkdown),
  };
}
