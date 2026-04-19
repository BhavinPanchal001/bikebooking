export const adminListingsService = {
  async approveListing({ listingId, adminEmail }) {
    console.log(`Mock: Approve listing ${listingId} by ${adminEmail}`);
  },

  async flagListing({ listingId, adminEmail }) {
    console.log(`Mock: Flag listing ${listingId} by ${adminEmail}`);
  },

  async closeListing({ listingId, adminEmail }) {
    console.log(`Mock: Close listing ${listingId} by ${adminEmail}`);
  },

  async reopenListing({ listingId, adminEmail }) {
    console.log(`Mock: Reopen listing ${listingId} by ${adminEmail}`);
  },

  async deleteListing({ listingId }) {
    console.log(`Mock: Delete listing ${listingId}`);
  },
};

