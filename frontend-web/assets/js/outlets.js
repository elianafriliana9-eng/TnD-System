/**
 * Outlets Management
 * TND System - Frontend
 */

// Main function to display the outlets page
async function showOutlets() {
    setActiveMenuItem('Outlets');
    
    const contentArea = document.getElementById('content-area');
    contentArea.innerHTML = showLoading();
    
    try {
        const outletsHTML = `
            <div class="fade-in">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2><i class="fas fa-store me-2"></i>Outlets Management</h2>
                    <button class="btn btn-primary" id="addOutletBtn">
                        <i class="fas fa-plus me-2"></i>Add Outlet
                    </button>
                </div>
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5><i class="fas fa-list me-2"></i>All Outlets</h5>
                        <div class="col-md-4">
                            <select class="form-select" id="divisionFilter"><option value="">All Divisions</option></select>
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped" id="outletsTable">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Division</th>
                                        <th>Address</th>
                                        <th>Phone</th>
                                        <th>Manager</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody></tbody>
                            </table>
                        </div>
                        <nav aria-label="Outlets pagination">
                            <ul class="pagination justify-content-center" id="outletsPagination"></ul>
                        </nav>
                    </div>
                </div>
            </div>
        `;
        
        contentArea.innerHTML = outletsHTML;
        
        // Initialize or re-initialize the manager
        if (!window.outletManager) {
            window.outletManager = new OutletManager(contentArea);
        } else {
            window.outletManager.reinit(contentArea);
        }
        
    } catch (error) {
        contentArea.innerHTML = showError('Failed to load outlets: ' + error.message);
    }
}

class OutletManager {
    constructor(container) {
        this.container = container;
    this.outlets = [];
    this.currentPage = 1;
    this.totalPages = 1;
    this.selectedDivisionId = '';
    this.modalInstance = null;
    this.init();
    }

    init() {
    this.loadDivisionsForFilter();
    this.loadOutlets();
    this.bindContainerEvents();
    this.createOutletModal(); // Ensures modal is in the DOM
    this.bindModalEvents();
    }

    reinit(container) {
        this.container = container;
        this.loadOutlets();
        this.bindContainerEvents();
    }

    bindContainerEvents() {
        // Use a specific handler for this container to avoid duplicate listeners
        this.container.onclick = (e) => {
            const addBtn = e.target.closest('#addOutletBtn');
            const editBtn = e.target.closest('.edit-outlet-btn');
            const deleteBtn = e.target.closest('.delete-outlet-btn');
            const pageLink = e.target.closest('.page-link');

            if (addBtn) this.showAddModal();
            else if (editBtn) this.showEditModal(editBtn.dataset.id);
            else if (deleteBtn) this.deleteOutlet(deleteBtn.dataset.id);
            else if (pageLink) {
                e.preventDefault();
                const page = parseInt(pageLink.dataset.page);
                if (page && page !== this.currentPage) {
                    this.currentPage = page;
                    this.loadOutlets();
                }
            }
        };
        // Division filter event
        const divisionFilter = this.container.querySelector('#divisionFilter');
        if (divisionFilter) {
            divisionFilter.onchange = (e) => {
                this.selectedDivisionId = e.target.value;
                this.currentPage = 1;
                this.loadOutlets();
            };
        }
    }

    bindModalEvents() {
        const modalEl = document.getElementById('outletModal');
        if (modalEl && !modalEl.dataset.eventsBound) {
            modalEl.addEventListener('click', (e) => {
                if (e.target.closest('#saveOutletBtn')) {
                    this.saveOutlet();
                }
            });
            modalEl.dataset.eventsBound = 'true';
        }
    }

    async loadOutlets(search = '') {
        const tbody = this.container.querySelector('#outletsTable tbody');
        tbody.innerHTML = `<tr><td colspan="8" class="text-center"><div class="spinner-border"></div></td></tr>`;
        
        try {
        let url = `/outlets.php?page=${this.currentPage}&limit=10`;
        if (this.selectedDivisionId) {
            url += `&division_id=${this.selectedDivisionId}`;
        }
        const response = await API.get(url);
            if (!response.success) throw new Error(response.message || 'Failed to load outlets');
            
            this.outlets = response.data.data;
            this.totalPages = response.data.pagination.pages;
            this.renderOutlets();
            this.renderPagination();

        } catch (error) {
            console.error('Error loading outlets:', error);
            tbody.innerHTML = `<tr><td colspan="8" class="text-center text-danger"><i class="fas fa-exclamation-triangle me-2"></i>${error.message}</td></tr>`;
        }
        }

        async loadDivisionsForFilter() {
            const divisionFilter = this.container.querySelector('#divisionFilter');
            if (!divisionFilter) return;
            divisionFilter.innerHTML = '<option value="">All Divisions</option>';
            try {
                const response = await API.get('/divisions.php?simple=true');
                if (!response.success) throw new Error(response.message);
                response.data.forEach(division => {
                    const option = new Option(division.name, division.id);
                    divisionFilter.add(option);
                });
            } catch (error) {
                console.error('Failed to load divisions:', error);
                divisionFilter.innerHTML = '<option value="">Error loading divisions</option>';
            }
    }

    renderOutlets() {
        const tbody = this.container.querySelector('#outletsTable tbody');
        tbody.innerHTML = '';
        if (this.outlets.length === 0) {
            tbody.innerHTML = `<tr><td colspan="8" class="text-center text-muted"><i class="fas fa-inbox me-2"></i>No outlets found</td></tr>`;
            return;
        }
        this.outlets.forEach(outlet => {
            const row = tbody.insertRow();
            row.innerHTML = `
                <td>${outlet.id}</td>
                <td>${outlet.name}</td>
                <td>${outlet.division_name || 'N/A'}</td>
                <td class="text-truncate" style="max-width: 200px;" title="${outlet.address}">${outlet.address}</td>
                <td>${outlet.phone}</td>
                <td>${outlet.manager_name || ''}</td>
                <td><span class="badge bg-${outlet.status === 'active' ? 'success' : 'secondary'}">${outlet.status}</span></td>
                <td>
                    <div class="btn-group" role="group">
                        <button class="btn btn-sm btn-outline-primary edit-outlet-btn" data-id="${outlet.id}" title="Edit"><i class="fas fa-edit"></i></button>
                        <button class="btn btn-sm btn-outline-danger delete-outlet-btn" data-id="${outlet.id}" title="Delete"><i class="fas fa-trash"></i></button>
                    </div>
                </td>
            `;
        });
    }

    renderPagination() {
        const pagination = this.container.querySelector('#outletsPagination');
        if (!pagination || this.totalPages <= 1) {
            pagination.innerHTML = '';
            return;
        }
        let html = '';
        html += `<li class="page-item ${this.currentPage === 1 ? 'disabled' : ''}"><a class="page-link" href="#" data-page="${this.currentPage - 1}">Previous</a></li>`;
        for (let i = 1; i <= this.totalPages; i++) {
            html += `<li class="page-item ${i === this.currentPage ? 'active' : ''}"><a class="page-link" href="#" data-page="${i}">${i}</a></li>`;
        }
        html += `<li class="page-item ${this.currentPage === this.totalPages ? 'disabled' : ''}"><a class="page-link" href="#" data-page="${this.currentPage + 1}">Next</a></li>`;
        pagination.innerHTML = html;
    }

    async loadDivisionsForModal(selectedDivisionId = null) {
        const divisionSelect = document.getElementById('outletDivision');
        divisionSelect.innerHTML = '<option value="">Loading divisions...</option>';
        try {
            const response = await API.get('/divisions.php?simple=true');
            if (!response.success) throw new Error(response.message);
            divisionSelect.innerHTML = '<option value="">Select a Division</option>';
            response.data.forEach(division => {
                const option = new Option(division.name, division.id);
                option.selected = (selectedDivisionId && division.id == selectedDivisionId);
                divisionSelect.add(option);
            });
        } catch (error) {
            console.error('Failed to load divisions:', error);
            divisionSelect.innerHTML = '<option value="">Error loading divisions</option>';
        }
    }

    createOutletModal() {
        if (document.getElementById('outletModal')) return;
        const modalHtml = `
            <div class="modal fade" id="outletModal" tabindex="-1">
                <div class="modal-dialog"><div class="modal-content">
                    <div class="modal-header"><h5 class="modal-title" id="outletModalTitle"></h5><button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>
                    <div class="modal-body">
                        <form id="outletForm">
                            <input type="hidden" id="outletId">
                            <div class="mb-3"><label for="outletDivision" class="form-label">Division *</label><select class="form-select" id="outletDivision" required><option value="">Select a Division</option></select></div>
                            <div class="mb-3"><label for="outletName" class="form-label">Name *</label><input type="text" class="form-control" id="outletName" required></div>
                            <div class="mb-3"><label for="outletCode" class="form-label">Code *</label><input type="text" class="form-control" id="outletCode" required></div>
                            <div class="mb-3"><label for="outletAddress" class="form-label">Address *</label><textarea class="form-control" id="outletAddress" rows="3" required></textarea></div>
                            <div class="mb-3"><label for="outletPhone" class="form-label">Phone *</label><input type="text" class="form-control" id="outletPhone" required></div>
                            <div class="mb-3"><label for="outletManager" class="form-label">Manager *</label><input type="text" class="form-control" id="outletManager" required></div>
                            <div class="mb-3"><label for="outletStatus" class="form-label">Status</label><select class="form-select" id="outletStatus"><option value="active">Active</option><option value="inactive">Inactive</option></select></div>
                        </form>
                    </div>
                    <div class="modal-footer"><button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button><button type="button" class="btn btn-primary" id="saveOutletBtn"><i class="fas fa-save me-2"></i>Save</button></div>
                </div></div>
            </div>`;
        document.body.insertAdjacentHTML('beforeend', modalHtml);
        this.modalInstance = new bootstrap.Modal(document.getElementById('outletModal'));
    }

    showAddModal() {
        const form = document.getElementById('outletForm');
        form.reset();
        document.getElementById('outletId').value = '';
        document.getElementById('outletModalTitle').textContent = 'Add Outlet';
        this.loadDivisionsForModal();
        this.modalInstance.show();
    }

    async showEditModal(id) {
        const form = document.getElementById('outletForm');
        form.reset();
        try {
            const response = await API.get(`/outlets.php?id=${id}`);
            if (!response.success) throw new Error(response.message);
            const outlet = response.data;
            document.getElementById('outletModalTitle').textContent = 'Edit Outlet';
            document.getElementById('outletId').value = outlet.id;
            document.getElementById('outletName').value = outlet.name;
            document.getElementById('outletCode').value = outlet.code;
            document.getElementById('outletAddress').value = outlet.address;
            document.getElementById('outletPhone').value = outlet.phone;
            document.getElementById('outletManager').value = outlet.manager_name;
            document.getElementById('outletStatus').value = outlet.status;
            await this.loadDivisionsForModal(outlet.division_id);
            this.modalInstance.show();
        } catch (error) {
            Swal.fire('Error', error.message || 'Failed to load outlet data', 'error');
        }
    }

    async saveOutlet() {
        const form = document.getElementById('outletForm');
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }
        
        const outletData = {
            division_id: document.getElementById('outletDivision').value,
            name: document.getElementById('outletName').value,
            code: document.getElementById('outletCode').value,
            address: document.getElementById('outletAddress').value,
            phone: document.getElementById('outletPhone').value,
            manager: document.getElementById('outletManager').value,
            status: document.getElementById('outletStatus').value
        };
        
        console.log('=== OUTLET SAVE DEBUG ===');
        console.log('Form data:', outletData);
        
        const id = document.getElementById('outletId').value;
        console.log('Outlet ID:', id);
        console.log('Method:', id ? 'PUT' : 'POST');
        
        try {
            const response = id ? await API.put(`/outlets.php?id=${id}`, outletData) : await API.post('/outlets.php', outletData);
            console.log('API Response:', response);
            if (!response.success) throw new Error(response.message);
            Swal.fire('Success', response.message || 'Outlet saved successfully', 'success');
            this.modalInstance.hide();
            this.loadOutlets();
        } catch (error) {
            console.error('Save outlet error:', error);
            Swal.fire('Error', error.message || 'Failed to save outlet', 'error');
        }
    }

    async deleteOutlet(id) {
        const result = await Swal.fire({ title: 'Are you sure?', text: 'This cannot be undone!', icon: 'warning', showCancelButton: true, confirmButtonColor: '#d33', confirmButtonText: 'Yes, delete it!' });
        if (!result.isConfirmed) return;
        try {
            const response = await API.delete(`/outlets.php?id=${id}`);
            if (!response.success) throw new Error(response.message);
            Swal.fire('Success', response.message || 'Outlet deleted successfully', 'success');
            this.loadOutlets();
        } catch (error) {
            Swal.fire('Error', error.message || 'Failed to delete outlet', 'error');
        }
    }

    searchOutlets(search) {
    // Search feature removed
    }
}