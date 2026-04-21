import { useEffect, useState } from 'react';
import { createCmsPageDraft, normalizeCmsPageSlug, validateCmsPageDraft } from '../data/models/cmsPageModel';
import { MarkdownPreview } from './MarkdownPreview';

const defaultValues = {
  slug: '',
  title: '',
  bodyMarkdown: '',
  version: 0,
  publishedVersion: 0,
  publishedAt: null,
  isPublished: false,
};

export function CmsPageEditorDialog({
  open,
  initialValues = defaultValues,
  isSaving = false,
  submitError = '',
  onClose,
  onSubmit,
}) {
  const [values, setValues] = useState(defaultValues);
  const [errors, setErrors] = useState({});
  const [slugTouched, setSlugTouched] = useState(false);

  const isCreate = !initialValues?.slug;

  useEffect(() => {
    if (!open) {
      return;
    }

    setValues({ ...defaultValues, ...initialValues });
    setErrors({});
    setSlugTouched(false);
  }, [initialValues, open]);

  if (!open) {
    return null;
  }

  function clearFieldError(fieldName) {
    setErrors((current) => {
      if (!current[fieldName]) {
        return current;
      }

      const nextErrors = { ...current };
      delete nextErrors[fieldName];
      return nextErrors;
    });
  }

  function handleTitleChange(nextTitle) {
    setValues((current) => {
      const nextValues = {
        ...current,
        title: nextTitle,
      };

      if (isCreate && !slugTouched) {
        nextValues.slug = normalizeCmsPageSlug(nextTitle);
      }

      return nextValues;
    });
    clearFieldError('title');
  }

  function handleSlugChange(nextSlug) {
    setSlugTouched(true);
    setValues((current) => ({
      ...current,
      slug: normalizeCmsPageSlug(nextSlug),
    }));
    clearFieldError('slug');
  }

  function handleBodyChange(nextBodyMarkdown) {
    setValues((current) => ({
      ...current,
      bodyMarkdown: nextBodyMarkdown,
    }));
    clearFieldError('bodyMarkdown');
  }

  async function handleSubmit(event) {
    event.preventDefault();

    const sanitizedDraft = createCmsPageDraft(values);
    const nextErrors = validateCmsPageDraft(sanitizedDraft, { isCreate });
    setErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      return;
    }

    await onSubmit({
      ...values,
      ...sanitizedDraft,
    });
  }

  const dialogTitle = isCreate ? 'Create CMS page' : 'Edit CMS page';
  const dialogSubtitle = isCreate
    ? 'Create a draft first, then publish once the preview reads the way you want it to in the app.'
    : 'Update the draft content here. Publishing will replace the live version used by the mobile app.';

  return (
    <div
      className="dialog-backdrop"
      role="presentation"
      onClick={() => {
        if (!isSaving) {
          onClose();
        }
      }}
    >
      <section
        className="dialog-card dialog-card-wide"
        role="dialog"
        aria-modal="true"
        aria-label={dialogTitle}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="dialog-head">
          <div>
            <h3>{dialogTitle}</h3>
            <p>{dialogSubtitle}</p>
          </div>
        </div>

        <form className="dialog-form cms-editor-form" onSubmit={handleSubmit}>
          <div className="cms-editor-grid">
            <div className="cms-editor-pane">
              <div className="dialog-form-grid dialog-form-grid-single">
                <label className="field">
                  <span>Slug</span>
                  <input
                    type="text"
                    value={values.slug ?? ''}
                    onChange={(event) => handleSlugChange(event.target.value)}
                    placeholder="privacy-policy"
                    autoFocus={isCreate}
                    disabled={!isCreate || isSaving}
                    autoComplete="off"
                  />
                  <small>Stored as cms_pages/{'{slug}'} so the mobile app can read a stable document path.</small>
                  {errors.slug ? <span className="field-error">{errors.slug}</span> : null}
                </label>

                <label className="field">
                  <span>Page title</span>
                  <input
                    type="text"
                    value={values.title ?? ''}
                    onChange={(event) => handleTitleChange(event.target.value)}
                    placeholder="Privacy Policy"
                    autoFocus={!isCreate}
                    disabled={isSaving}
                    autoComplete="off"
                  />
                  <small>This title is used for both the admin list and the mobile screen header when published.</small>
                  {errors.title ? <span className="field-error">{errors.title}</span> : null}
                </label>

                <label className="field field-full">
                  <span>Markdown content</span>
                  <textarea
                    value={values.bodyMarkdown ?? ''}
                    onChange={(event) => handleBodyChange(event.target.value)}
                    placeholder={'## Section heading\n\nWrite the copy that should appear in the app.'}
                    rows={20}
                    disabled={isSaving}
                  />
                  <small>Headings, paragraphs, numbered lists, and bullets render in the mobile reader.</small>
                  {errors.bodyMarkdown ? (
                    <span className="field-error">{errors.bodyMarkdown}</span>
                  ) : null}
                </label>
              </div>
            </div>

            <div className="cms-preview-pane">
              <div className="cms-preview-head">
                <div>
                  <strong>Live Preview</strong>
                  <span>Mirrors the published app layout and markdown rendering.</span>
                </div>
                <div className="cms-meta-stack">
                  <span className="cms-meta-chip">Draft v{Number(values.version) || 0}</span>
                  <span className="cms-meta-chip">
                    Published v{Number(values.publishedVersion) || 0}
                  </span>
                </div>
              </div>

              <div className="cms-preview-shell">
                <div className="cms-preview-appbar">
                  <span className="cms-preview-kicker">Bikebooking</span>
                  <strong>{values.title?.trim() || 'Untitled page'}</strong>
                </div>
                <MarkdownPreview value={values.bodyMarkdown} />
              </div>
            </div>
          </div>

          {submitError ? <div className="feedback-banner feedback-banner-error">{submitError}</div> : null}

          <div className="dialog-actions">
            <button
              type="button"
              className="secondary-button"
              onClick={onClose}
              disabled={isSaving}
            >
              Cancel
            </button>
            <button type="submit" className="primary-button" disabled={isSaving}>
              {isSaving ? 'Saving draft...' : isCreate ? 'Create draft' : 'Save draft'}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
