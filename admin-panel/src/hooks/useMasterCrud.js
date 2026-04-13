import { useEffect, useState } from 'react';

export function useMasterCrud({ service, singularLabel }) {
  const [records, setRecords] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [actionError, setActionError] = useState('');
  const [successMessage, setSuccessMessage] = useState('');
  const [isSaving, setIsSaving] = useState(false);
  const [deletingId, setDeletingId] = useState('');

  useEffect(() => {
    setLoading(true);
    setError('');

    const unsubscribe = service.subscribe({
      onData(nextRecords) {
        setRecords(nextRecords);
        setLoading(false);
        setError('');
      },
      onError(message) {
        setLoading(false);
        setError(message || `Unable to load ${singularLabel} records.`);
      },
    });

    return unsubscribe;
  }, [service, singularLabel]);

  function clearFeedback() {
    setActionError('');
    setSuccessMessage('');
  }

  async function createRecord(values) {
    clearFeedback();
    setIsSaving(true);

    try {
      await service.create(values);
      setSuccessMessage(`${singularLabel} created successfully.`);
      return true;
    } catch (error) {
      setActionError(error?.message || `Unable to create ${singularLabel}.`);
      return false;
    } finally {
      setIsSaving(false);
    }
  }

  async function updateRecord(id, values) {
    clearFeedback();
    setIsSaving(true);

    try {
      await service.update(id, values);
      setSuccessMessage(`${singularLabel} updated successfully.`);
      return true;
    } catch (error) {
      setActionError(error?.message || `Unable to update ${singularLabel}.`);
      return false;
    } finally {
      setIsSaving(false);
    }
  }

  async function deleteRecord(id) {
    clearFeedback();
    setDeletingId(id);

    try {
      await service.remove(id);
      setSuccessMessage(`${singularLabel} deleted successfully.`);
      return true;
    } catch (error) {
      setActionError(error?.message || `Unable to delete ${singularLabel}.`);
      return false;
    } finally {
      setDeletingId('');
    }
  }

  return {
    records,
    loading,
    error,
    actionError,
    successMessage,
    isSaving,
    deletingId,
    clearFeedback,
    createRecord,
    updateRecord,
    deleteRecord,
  };
}

