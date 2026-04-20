import { useEffect, useState } from 'react';

export function MasterRecordFormDialog({
  open,
  title,
  subtitle,
  fields,
  initialValues,
  validate,
  isSaving = false,
  submitError = '',
  onClose,
  onSubmit,
}) {
  const [values, setValues] = useState(initialValues);
  const [errors, setErrors] = useState({});

  useEffect(() => {
    if (open) {
      setValues(initialValues);
      setErrors({});
    }
  }, [initialValues, open]);

  if (!open) {
    return null;
  }

  async function handleSubmit(event) {
    event.preventDefault();

    const nextErrors = validate(values);
    setErrors(nextErrors);

    if (Object.keys(nextErrors).length > 0) {
      return;
    }

    await onSubmit(values);
  }

  function handleChange(fieldName, nextValue) {
    setValues((current) => ({
      ...current,
      [fieldName]: nextValue,
    }));

    setErrors((current) => {
      if (!current[fieldName]) {
        return current;
      }

      const nextErrors = { ...current };
      delete nextErrors[fieldName];
      return nextErrors;
    });
  }

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
        className="dialog-card"
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(event) => event.stopPropagation()}
      >
        <div className="dialog-head">
          <div>
            <h3>{title}</h3>
            <p>{subtitle}</p>
          </div>
        </div>

        <form className="dialog-form" onSubmit={handleSubmit}>
          <div className="dialog-form-grid">
            {fields.map((field) => {
              const isSelect = field.type === 'select';
              const isCheckbox = field.type === 'checkbox';
              return (
                <label
                  key={field.name}
                  className={`field ${field.fullWidth ? 'field-full' : ''} ${isCheckbox ? 'field-checkbox' : ''}`.trim()}
                >
                  <span>{field.label}</span>
                  {isSelect ? (
                    <select
                      value={values[field.name] ?? ''}
                      onChange={(event) => handleChange(field.name, event.target.value)}
                      required={field.required}
                      disabled={isSaving}
                    >
                      {(field.options ?? []).map((option) => (
                        <option key={option.value} value={option.value}>
                          {option.label}
                        </option>
                      ))}
                    </select>
                  ) : isCheckbox ? (
                    <input
                      type="checkbox"
                      checked={Boolean(values[field.name])}
                      onChange={(event) => handleChange(field.name, event.target.checked)}
                      disabled={isSaving}
                    />
                  ) : (
                    <input
                      type={field.type ?? 'text'}
                      value={values[field.name] ?? ''}
                      onChange={(event) => handleChange(field.name, event.target.value)}
                      placeholder={field.placeholder}
                      autoFocus={field.autoFocus}
                      required={field.required}
                      disabled={isSaving}
                      autoComplete="off"
                      inputMode={field.inputMode}
                      min={field.min}
                      max={field.max}
                      step={field.step}
                    />
                  )}
                  {field.helperText ? <small>{field.helperText}</small> : null}
                  {errors[field.name] ? (
                    <span className="field-error">{errors[field.name]}</span>
                  ) : null}
                  {typeof field.renderPreview === 'function'
                    ? field.renderPreview(values[field.name] ?? '', values)
                    : null}
                </label>
              );
            })}
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
              {isSaving ? 'Saving...' : 'Save changes'}
            </button>
          </div>
        </form>
      </section>
    </div>
  );
}
