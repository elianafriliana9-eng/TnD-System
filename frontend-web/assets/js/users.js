// Users management functionality
async function showUsers() {
    setActiveMenuItem('Users');
    
    const contentArea = document.getElementById('content-area');
    contentArea.innerHTML = showLoading();
    
    try {
        const response = await UsersAPI.getAll();
        
        if (response.success) {
            const users = response.data;
            
            const usersHTML = `
                <div class="fade-in">
                    <div class="d-flex justify-content-between align-items-center mb-4">
                        <h2><i class="fas fa-users me-2"></i>Users Management</h2>
                        <button class="btn btn-primary" onclick="showAddUserModal()">
                            <i class="fas fa-plus me-2"></i>Add User
                        </button>
                    </div>
                    
                    <div class="card">
                        <div class="card-header">
                            <h5><i class="fas fa-list me-2"></i>All Users</h5>
                        </div>
                        <div class="card-body">
                            <div class="table-responsive">
                                <table class="table table-hover">
                                    <thead>
                                        <tr>
                                            <th>Name</th>
                                            <th>Email</th>
                                            <th>Phone</th>
                                            <th>Division</th>
                                            <th>Role</th>
                                            <th>Status</th>
                                            <th>Created</th>
                                            <th>Actions</th>
                                        </tr>
                                    </thead>
                                    <tbody>
                                        ${users.map(user => `
                                            <tr>
                                                <td>
                                                    <div class="d-flex align-items-center">
                                                        <div class="avatar-circle me-2">
                                                            ${(user.full_name || user.username || 'U').charAt(0).toUpperCase()}
                                                        </div>
                                                        ${user.full_name || user.username || '-'}
                                                    </div>
                                                </td>
                                                <td>${user.email}</td>
                                                <td>${user.phone || '-'}</td>
                                                <td>${user.division_name || '-'}</td>
                                                <td>
                                                    <span class="badge ${getRoleBadge(user.role)}">
                                                        ${user.role.replace('_', ' ').toUpperCase()}
                                                    </span>
                                                </td>
                                                <td>
                                                    <span class="badge ${user.is_active ? 'bg-success' : 'bg-secondary'}">
                                                        ${user.is_active ? 'Active' : 'Inactive'}
                                                    </span>
                                                </td>
                                                <td>${formatDate(user.created_at)}</td>
                                                <td>
                                                    <button class="btn btn-sm btn-outline-primary me-1" onclick="showEditUserModal(${user.id})">
                                                        <i class="fas fa-edit"></i>
                                                    </button>
                                                    ${user.id !== currentUser.id ? `
                                                        <button class="btn btn-sm btn-outline-danger" onclick="deleteUser(${user.id})">
                                                            <i class="fas fa-trash"></i>
                                                        </button>
                                                    ` : ''}
                                                </td>
                                            </tr>
                                        `).join('')}
                                    </tbody>
                                </table>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            contentArea.innerHTML = usersHTML;
        }
    } catch (error) {
        contentArea.innerHTML = showError('Failed to load users: ' + error.message);
    }
}

function getRoleBadge(role) {
    const badges = {
        'super_admin': 'bg-danger',
        'admin': 'bg-warning',
        'supervisor': 'bg-info',
        'auditor': 'bg-primary',
        'trainer': 'bg-success',
        'staff': 'bg-secondary'
    };
    return badges[role] || 'bg-secondary';
}

function showAddUserModal() {
    const modalHTML = `
        <div class="modal fade" id="addUserModal" tabindex="-1">
            <div class="modal-dialog modal-lg">
                <div class="modal-content">
                    <div class="modal-header">
                        <h5 class="modal-title">
                            <i class="fas fa-user-plus me-2"></i>Add New User
                        </h5>
                        <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <form id="addUserForm">
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-floating mb-3">
                                        <input type="text" class="form-control" id="addUserName" required>
                                        <label for="addUserName">Full Name</label>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-floating mb-3">
                                        <input type="email" class="form-control" id="addUserEmail" required>
                                        <label for="addUserEmail">Email</label>
                                    </div>
                                </div>
                            </div>
                            <div class="row">
                                <div class="col-md-6">
                                    <div class="form-floating mb-3">
                                        <input type="password" class="form-control" id="addUserPassword" required minlength="6">
                                        <label for="addUserPassword">Password</label>
                                    </div>
                                </div>
                                <div class="col-md-6">
                                    <div class="form-floating mb-3">
                                        <input type="text" class="form-control" id="addUserPhone">
                                        <label for="addUserPhone">Phone</label>
                                    </div>
                                </div>
                            </div>
                            <div class="form-floating mb-3">
                                <select class="form-select" id="addUserDivision" required>
                                    <option value="">Select Division</option>
                                </select>
                                <label for="addUserDivision">Division</label>
                            </div>
                            <div class="form-floating mb-3">
                                <select class="form-select" id="addUserRole" required>
                                    <option value="">Select Role</option>
                                    <option value="admin">Admin</option>
                                    <option value="supervisor">Supervisor</option>
                                    <option value="trainer">Trainer</option>
                                    <option value="staff">Staff</option>
                                </select>
                                <label for="addUserRole">Role</label>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-primary" onclick="addUser()">Add User</button>
                    </div>
                </div>
            </div>
        </div>
    `;
    document.getElementById('modal-container').innerHTML = modalHTML;
    // Load divisions for dropdown
    const divisionSelect = document.getElementById('addUserDivision');
    if (divisionSelect) {
        divisionSelect.innerHTML = '<option value="">Loading divisions...</option>';
        API.get('/divisions.php?simple=true').then(response => {
            if (response.success) {
                divisionSelect.innerHTML = '<option value="">Select Division</option>';
                response.data.forEach(division => {
                    const option = new Option(division.name, division.id);
                    divisionSelect.add(option);
                });
            } else {
                divisionSelect.innerHTML = '<option value="">Error loading divisions</option>';
            }
        }).catch(() => {
            divisionSelect.innerHTML = '<option value="">Error loading divisions</option>';
        });
    }
    const modal = new bootstrap.Modal(document.getElementById('addUserModal'));
    modal.show();
}

async function addUser() {
    const name = document.getElementById('addUserName').value;
    const email = document.getElementById('addUserEmail').value;
    const password = document.getElementById('addUserPassword').value;
    const phone = document.getElementById('addUserPhone').value;
    const division_id = document.getElementById('addUserDivision').value;
    const role = document.getElementById('addUserRole').value;
    if (!name || !email || !password || !role || !division_id) {
        showErrorAlert('Please fill all required fields');
        return;
    }
    try {
        const response = await UsersAPI.create({
            full_name: name,
            email: email,
            password: password,
            phone: phone,
            division_id: division_id,
            role: role
        });
        if (response.success) {
            const modal = bootstrap.Modal.getInstance(document.getElementById('addUserModal'));
            modal.hide();
            showSuccess('User added successfully');
            showUsers(); // Refresh the users list
        }
    } catch (error) {
        showErrorAlert(error.message || 'Failed to add user');
    }
}

async function showEditUserModal(userId) {
    try {
        const response = await UsersAPI.getById(userId);
        
        if (response.success) {
            const user = response.data;
            
            const modalHTML = `
                <div class="modal fade" id="editUserModal" tabindex="-1">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">
                                    <i class="fas fa-user-edit me-2"></i>Edit User
                                </h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <form id="editUserForm">
                                    <input type="hidden" id="editUserId" value="${user.id}">
                                    
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-floating mb-3">
                                                <input type="text" class="form-control" id="editUserName" value="${user.full_name || user.username || ''}" required>
                                                <label for="editUserName">Full Name</label>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-floating mb-3">
                                                <input type="email" class="form-control" id="editUserEmail" value="${user.email}" required>
                                                <label for="editUserEmail">Email</label>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <div class="row">
                                        <div class="col-md-6">
                                            <div class="form-floating mb-3">
                                                <input type="text" class="form-control" id="editUserPhone" value="${user.phone || ''}">
                                                <label for="editUserPhone">Phone</label>
                                            </div>
                                        </div>
                                        <div class="col-md-6">
                                            <div class="form-floating mb-3">
                                                <select class="form-select" id="editUserRole" required>
                                                    <option value="admin" ${user.role === 'admin' ? 'selected' : ''}>Admin</option>
                                                    <option value="supervisor" ${user.role === 'supervisor' ? 'selected' : ''}>Supervisor</option>
                                                    <option value="trainer" ${user.role === 'trainer' ? 'selected' : ''}>Trainer</option>
                                                    <option value="staff" ${user.role === 'staff' ? 'selected' : ''}>Staff</option>
                                                </select>
                                                <label for="editUserRole">Role</label>
                                            </div>
                                        </div>
                                    </div>
                                    
                                    <div class="form-check">
                                        <input class="form-check-input" type="checkbox" id="editUserActive" ${user.is_active ? 'checked' : ''}>
                                        <label class="form-check-label" for="editUserActive">
                                            Active User
                                        </label>
                                    </div>
                                </form>
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-warning" onclick="showChangeUserPasswordModal(${userId})">
                                    <i class="bi bi-key"></i> Change Password
                                </button>
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                                <button type="button" class="btn btn-primary" onclick="updateUser()">Update User</button>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            document.getElementById('modal-container').innerHTML = modalHTML;
            const modal = new bootstrap.Modal(document.getElementById('editUserModal'));
            modal.show();
        }
    } catch (error) {
        showErrorAlert('Failed to load user details: ' + error.message);
    }
}

async function updateUser() {
    const userId = document.getElementById('editUserId').value;
    const name = document.getElementById('editUserName').value;
    const email = document.getElementById('editUserEmail').value;
    const phone = document.getElementById('editUserPhone').value;
    const role = document.getElementById('editUserRole').value;
    const isActive = document.getElementById('editUserActive').checked;
    
    if (!name || !email || !role) {
        showErrorAlert('Please fill all required fields');
        return;
    }
    
    try {
        const response = await UsersAPI.update(userId, {
            full_name: name,
            email: email,
            phone: phone,
            role: role,
            is_active: isActive ? 1 : 0
        });
        
        if (response.success) {
            const modal = bootstrap.Modal.getInstance(document.getElementById('editUserModal'));
            modal.hide();
            
            showSuccess('User updated successfully');
            showUsers(); // Refresh the users list
        }
    } catch (error) {
        showErrorAlert(error.message || 'Failed to update user');
    }
}

function showChangeUserPasswordModal(userId) {
    const modalHTML = `
        <div class="modal fade" id="changeUserPasswordModal" tabindex="-1">
            <div class="modal-dialog">
                <div class="modal-content">
                    <div class="modal-header bg-warning text-white">
                        <h5 class="modal-title">
                            <i class="bi bi-key"></i> Change User Password
                        </h5>
                        <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                    </div>
                    <div class="modal-body">
                        <div class="alert alert-info">
                            <i class="bi bi-info-circle"></i> Set a new password for this user. User will need to login with the new password.
                        </div>
                        <form id="changeUserPasswordForm">
                            <input type="hidden" id="changePasswordUserId" value="${userId}">
                            <div class="form-floating mb-3">
                                <input type="password" class="form-control" id="newUserPassword" required minlength="6">
                                <label for="newUserPassword">New Password</label>
                            </div>
                            <div class="form-floating mb-3">
                                <input type="password" class="form-control" id="confirmUserPassword" required minlength="6">
                                <label for="confirmUserPassword">Confirm New Password</label>
                            </div>
                            <div class="form-check mb-3">
                                <input class="form-check-input" type="checkbox" id="showUserPassword" onchange="toggleUserPasswordVisibility()">
                                <label class="form-check-label" for="showUserPassword">
                                    Show Password
                                </label>
                            </div>
                        </form>
                    </div>
                    <div class="modal-footer">
                        <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
                        <button type="button" class="btn btn-warning" onclick="changeUserPassword()">
                            <i class="bi bi-check-circle"></i> Change Password
                        </button>
                    </div>
                </div>
            </div>
        </div>
    `;
    
    document.getElementById('modal-container').innerHTML = modalHTML;
    const modal = new bootstrap.Modal(document.getElementById('changeUserPasswordModal'));
    modal.show();
}

function toggleUserPasswordVisibility() {
    const newPassword = document.getElementById('newUserPassword');
    const confirmPassword = document.getElementById('confirmUserPassword');
    const checkbox = document.getElementById('showUserPassword');
    
    const type = checkbox.checked ? 'text' : 'password';
    newPassword.type = type;
    confirmPassword.type = type;
}

async function changeUserPassword() {
    const userId = document.getElementById('changePasswordUserId').value;
    const newPassword = document.getElementById('newUserPassword').value;
    const confirmPassword = document.getElementById('confirmUserPassword').value;
    
    if (!newPassword || !confirmPassword) {
        showErrorAlert('Please fill all fields');
        return;
    }
    
    if (newPassword.length < 6) {
        showErrorAlert('Password must be at least 6 characters');
        return;
    }
    
    if (newPassword !== confirmPassword) {
        showErrorAlert('Passwords do not match');
        return;
    }
    
    try {
        const response = await UsersAPI.changePassword(userId, newPassword);
        
        if (response.success) {
            const modal = bootstrap.Modal.getInstance(document.getElementById('changeUserPasswordModal'));
            modal.hide();
            
            showSuccess('Password changed successfully');
        }
    } catch (error) {
        showErrorAlert(error.message || 'Failed to change password');
    }
}

async function deleteUser(userId) {
    const result = await confirmDelete('Are you sure you want to delete this user?');
    
    if (result.isConfirmed) {
        try {
            const response = await UsersAPI.delete(userId);
            
            if (response.success) {
                showSuccess('User deleted successfully');
                showUsers(); // Refresh the users list
            }
        } catch (error) {
            showErrorAlert(error.message || 'Failed to delete user');
        }
    }
}