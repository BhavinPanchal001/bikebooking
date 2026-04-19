export const adminUsersService = {
  async blockUser({ userId, adminEmail }) {
    console.log(`Mock: Block user ${userId} by ${adminEmail}`);
  },

  async unblockUser({ userId }) {
    console.log(`Mock: Unblock user ${userId}`);
  },

  async deleteUser({ userId }) {
    console.log(`Mock: Delete user ${userId}`);
  },
};

