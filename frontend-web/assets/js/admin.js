// Main admin functionality and navigation
function setActiveMenuItem(menuName) {
    // Remove active class from all menu items
    const selectors = ['.list-group-item', '.menu-item'];
    selectors.forEach(selector => {
        document.querySelectorAll(selector).forEach(item => {
            item.classList.remove('active');
        });
    });
    
    // Add active class to current menu item
    selectors.forEach(selector => {
        document.querySelectorAll(selector).forEach(item => {
            if (item.textContent.trim().includes(menuName)) {
                item.classList.add('active');
            }
        });
    });
}




function showChecklistManagement() {
    setActiveMenuItem('Checklist Management');
    const contentArea = document.getElementById('content-area');

    const initialHTML = `
        <div class="fade-in">
            <!-- Header Section -->
            <div class="dashboard-header mb-4">
                <div>
                    <h2 class="mb-1" style="font-weight: 600; color: #1a1a1a;">
                        <i class="fas fa-clipboard-list me-2" style="color: #667eea;"></i>
                        Checklist Management
                    </h2>
                    <p class="text-muted mb-0">Manage checklist categories and items for each division</p>
                </div>
            </div>

            <!-- Division Cards Grid -->
            <div id="division-cards" class="row g-3"></div>

            <!-- Checklist Details View -->
            <div id="checklist-details" class="d-none">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h3 class="mb-1" style="font-weight: 600;" id="division-name"></h3>
                        <p class="text-muted mb-0">Manage categories and checklist points</p>
                    </div>
                    <button id="back-to-divisions" class="btn btn-outline-secondary">
                        <i class="fas fa-arrow-left me-2"></i>Back to Divisions
                    </button>
                </div>
                <div id="categories-accordion"></div>
            </div>
        </div>
    `;
    contentArea.innerHTML = initialHTML;

    const divisionCards = document.getElementById('division-cards');
    const checklistDetails = document.getElementById('checklist-details');
    const divisionName = document.getElementById('division-name');
    const categoriesAccordion = document.getElementById('categories-accordion');
    const backToDivisions = document.getElementById('back-to-divisions');

    async function showDivisionCards() {
        try {
            const response = await API.get('/divisions.php?simple=true');
            if (response.success) {
                const divisions = response.data;
                const gradients = [
                    'linear-gradient(135deg, #667eea 0%, #764ba2 100%)',
                    'linear-gradient(135deg, #f093fb 0%, #f5576c 100%)',
                    'linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)',
                    'linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)',
                    'linear-gradient(135deg, #fa709a 0%, #fee140 100%)',
                    'linear-gradient(135deg, #30cfd0 0%, #330867 100%)'
                ];
                
                divisionCards.innerHTML = '';
                divisions.forEach((division, index) => {
                    const gradient = gradients[index % gradients.length];
                    const card = `
                        <div class="col-md-4 col-lg-3">
                            <div class="division-card-modern" data-id="${division.id}" data-name="${division.name}">
                                <div class="division-icon" style="background: ${gradient};">
                                    <i class="fas fa-briefcase"></i>
                                </div>
                                <h5 class="division-title">${division.name}</h5>
                                <p class="division-subtitle">Click to manage checklist</p>
                                <div class="division-arrow">
                                    <i class="fas fa-arrow-right"></i>
                                </div>
                            </div>
                        </div>
                    `;
                    divisionCards.innerHTML += card;
                });
            } else {
                divisionCards.innerHTML = `
                    <div class="col-12">
                        <div class="alert alert-danger" role="alert">
                            <i class="fas fa-exclamation-circle me-2"></i>
                            Error loading divisions: ${response.message}
                        </div>
                    </div>
                `;
            }
        } catch (error) {
            divisionCards.innerHTML = `
                <div class="col-12">
                    <div class="alert alert-danger" role="alert">
                        <i class="fas fa-exclamation-circle me-2"></i>
                        Error loading divisions: ${error.message}
                    </div>
                </div>
            `;
        }

        checklistDetails.classList.add('d-none');
        divisionCards.classList.remove('d-none');
    }

    async function showChecklistDetailsView(divisionId, name) {
        divisionName.textContent = name;
        categoriesAccordion.innerHTML = '<div class="spinner-border" role="status"><span class="visually-hidden">Loading...</span></div>';

        try {
            const response = await API.get(`/divisions.php?id=${divisionId}`);
            if (response.success) {
                const division = response.data;
                const categories = division.categories || [];
                categoriesAccordion.innerHTML = '';

                // Add Category button
                const addCategoryBtn = `
                    <div class="mb-4">
                        <button class="btn btn-primary btn-lg" id="add-category-btn" data-division-id="${divisionId}">
                            <i class="fas fa-plus-circle me-2"></i>Add New Category
                        </button>
                    </div>
                `;
                categoriesAccordion.innerHTML += addCategoryBtn;

                if (categories.length === 0) {
                    categoriesAccordion.innerHTML += `
                        <div class="empty-state">
                            <i class="fas fa-clipboard-list fa-4x text-muted mb-3"></i>
                            <h5>No Categories Yet</h5>
                            <p class="text-muted">Start by adding your first checklist category</p>
                        </div>
                    `;
                } else {
                    categories.forEach((category, index) => {
                        const accordionItemId = `collapse${index}`;
                        const headingId = `heading${index}`;
                        const points = category.points || [];
                        const categoryColors = [
                            '#667eea', '#f5576c', '#00f2fe', '#38f9d7', '#fee140', '#330867'
                        ];
                        const categoryColor = categoryColors[index % categoryColors.length];
                        
                        const accordionItem = `
                            <div class="card-clean mb-3">
                                <div class="category-header" id="${headingId}">
                                    <div class="category-header-content">
                                        <div class="category-icon" style="background: ${categoryColor};">
                                            <i class="fas fa-folder"></i>
                                        </div>
                                        <div class="category-info">
                                            <h6 class="category-name mb-0">${category.name}</h6>
                                            <small class="text-muted">${points.length} checklist item(s)</small>
                                        </div>
                                    </div>
                                    <div class="category-actions">
                                        <button class="btn btn-sm btn-light me-2" data-bs-toggle="collapse" data-bs-target="#${accordionItemId}" aria-expanded="false" aria-controls="${accordionItemId}">
                                            <i class="fas fa-chevron-down"></i>
                                        </button>
                                        <button class="btn btn-sm btn-outline-primary me-2 edit-category-btn" data-id="${category.id}" data-name="${category.name}" data-description="${category.description}">
                                            <i class="fas fa-edit"></i> Edit
                                        </button>
                                        <button class="btn btn-sm btn-outline-danger delete-category-btn" data-id="${category.id}">
                                            <i class="fas fa-trash"></i> Delete
                                        </button>
                                    </div>
                                </div>
                                <div id="${accordionItemId}" class="collapse" aria-labelledby="${headingId}">
                                    <div class="category-body">
                                        <button class="btn btn-success btn-sm mb-3 add-point-btn" data-category-id="${category.id}">
                                            <i class="fas fa-plus me-2"></i>Add Checklist Item
                                        </button>
                                        ${points.length === 0 ? `
                                            <div class="text-center text-muted py-4">
                                                <i class="fas fa-list-ul fa-2x mb-2"></i>
                                                <p>No checklist items yet</p>
                                            </div>
                                        ` : `
                                            <div class="checklist-items">
                                                ${points.map((point, idx) => `
                                                    <div class="checklist-item">
                                                        <div class="checklist-number">${idx + 1}</div>
                                                        <div class="checklist-content">
                                                            <p class="mb-0">${point.question}</p>
                                                        </div>
                                                        <div class="checklist-actions">
                                                            <button class="btn btn-sm btn-outline-primary edit-point-btn" data-id="${point.id}" data-question="${point.question}" data-category-id="${point.category_id}">
                                                                <i class="fas fa-edit"></i>
                                                            </button>
                                                            <button class="btn btn-sm btn-outline-danger delete-point-btn" data-id="${point.id}">
                                                                <i class="fas fa-trash"></i>
                                                            </button>
                                                        </div>
                                                    </div>
                                                `).join('')}
                                            </div>
                                        `}
                                    </div>
                                </div>
                            </div>
                        `;
                        categoriesAccordion.innerHTML += accordionItem;
                    });
                }
            } else {
                categoriesAccordion.innerHTML = `<p class="text-danger">Error loading checklist details: ${response.message}</p>`;
            }
        } catch (error) {
            categoriesAccordion.innerHTML = `<p class="text-danger">Error loading checklist details: ${error.message}</p>`;
        }

        divisionCards.classList.add('d-none');
        checklistDetails.classList.remove('d-none');
    }

    divisionCards.addEventListener('click', function (event) {
        const card = event.target.closest('.division-card-modern');
        if (card) {
            const divisionId = card.dataset.id;
            const name = card.dataset.name;
            showChecklistDetailsView(divisionId, name);
        }
    });

    // Event listeners for CRUD operations
    contentArea.addEventListener('click', async function (event) {
        const target = event.target;
        const divisionId = document.querySelector('#add-category-btn')?.dataset.divisionId;

        // Add Category
        if (target.matches('#add-category-btn')) {
            const { value: formValues } = await Swal.fire({
                title: 'Add Category',
                html:
                    '<input id="swal-input1" class="swal2-input" placeholder="Name">' +
                    '<input id="swal-input2" class="swal2-input" placeholder="Description">',
                focusConfirm: false,
                preConfirm: () => {
                    return [
                        document.getElementById('swal-input1').value,
                        document.getElementById('swal-input2').value
                    ]
                }
            });

            if (formValues) {
                const [name, description] = formValues;
                const response = await API.post('/checklist-categories.php', { division_id: divisionId, name, description });
                if (response.success) {
                    showChecklistDetailsView(divisionId, divisionName.textContent);
                } else {
                    Swal.fire('Error', response.message, 'error');
                }
            }
        }

        // Edit Category
        if (target.matches('.edit-category-btn')) {
            const categoryId = target.dataset.id;
            const oldName = target.dataset.name;
            const oldDescription = target.dataset.description;

            const { value: formValues } = await Swal.fire({
                title: 'Edit Category',
                html:
                    `<input id="swal-input1" class="swal2-input" placeholder="Name" value="${oldName}">` +
                    `<input id="swal-input2" class="swal2-input" placeholder="Description" value="${oldDescription}">`,
                focusConfirm: false,
                preConfirm: () => {
                    return [
                        document.getElementById('swal-input1').value,
                        document.getElementById('swal-input2').value
                    ]
                }
            });

            if (formValues) {
                const [name, description] = formValues;
                const response = await API.put(`/checklist-categories.php?id=${categoryId}`, { name, description });
                if (response.success) {
                    showChecklistDetailsView(divisionId, divisionName.textContent);
                } else {
                    Swal.fire('Error', response.message, 'error');
                }
            }
        }

        // Delete Category
        if (target.matches('.delete-category-btn')) {
            const categoryId = target.dataset.id;

            Swal.fire({
                title: 'Are you sure?',
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, delete it!'
            }).then(async (result) => {
                if (result.isConfirmed) {
                    const response = await API.delete(`/checklist-categories.php?id=${categoryId}`);
                    if (response.success) {
                        showChecklistDetailsView(divisionId, divisionName.textContent);
                    } else {
                        Swal.fire('Error', response.message, 'error');
                    }
                }
            });
        }

        // Add Point
        if (target.matches('.add-point-btn')) {
            const categoryId = target.dataset.categoryId;

            const { value: question } = await Swal.fire({
                title: 'Add Checklist Point',
                input: 'text',
                inputLabel: 'Question',
                inputPlaceholder: 'Enter the question for the checklist point'
            });

            if (question) {
                const response = await API.post('/checklist-points.php', { category_id: categoryId, question: question, description: question });
                if (response.success) {
                    showChecklistDetailsView(divisionId, divisionName.textContent);
                } else {
                    Swal.fire('Error', response.message, 'error');
                }
            }
        }

        // Edit Point
        if (target.matches('.edit-point-btn')) {
            const pointId = target.dataset.id;
            const oldQuestion = target.dataset.question;
            const categoryId = target.dataset.categoryId;

            const { value: question } = await Swal.fire({
                title: 'Edit Checklist Point',
                input: 'text',
                inputLabel: 'Question',
                inputValue: oldQuestion,
                inputPlaceholder: 'Enter the question for the checklist point'
            });

            if (question) {
                const response = await API.put(`/checklist-points.php?id=${pointId}`, { question: question, description: question, category_id: categoryId });
                if (response.success) {
                    showChecklistDetailsView(divisionId, divisionName.textContent);
                } else {
                    Swal.fire('Error', response.message, 'error');
                }
            }
        }

        // Delete Point
        if (target.matches('.delete-point-btn')) {
            const pointId = target.dataset.id;

            Swal.fire({
                title: 'Are you sure?',
                text: "You won't be able to revert this!",
                icon: 'warning',
                showCancelButton: true,
                confirmButtonColor: '#3085d6',
                cancelButtonColor: '#d33',
                confirmButtonText: 'Yes, delete it!'
            }).then(async (result) => {
                if (result.isConfirmed) {
                    const response = await API.delete(`/checklist-points.php?id=${pointId}`);
                    if (response.success) {
                        showChecklistDetailsView(divisionId, divisionName.textContent);
                    } else {
                        Swal.fire('Error', response.message, 'error');
                    }
                }
            });
        }
    });

    backToDivisions.addEventListener('click', function () {
        showDivisionCards();
    });

    showDivisionCards();
}

async function showChecklistCategories() {

    setActiveMenuItem('Checklist Categories');
    
    const contentArea = document.getElementById('content-area');
    contentArea.innerHTML = showLoading();
    
    try {
        const categoriesHTML = `
            <div class="fade-in">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <h2><i class="fas fa-list me-2"></i>Checklist Categories</h2>
                    <button class="btn btn-primary" id="addCategoryBtn">
                        <i class="fas fa-plus me-2"></i>Add Category
                    </button>
                </div>
                
                <div class="card">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h5><i class="fas fa-list me-2"></i>All Categories</h5>
                        <div class="col-md-4">
                            <input type="text" class="form-control" id="categorySearch" placeholder="Search categories...">
                        </div>
                    </div>
                    <div class="card-body">
                        <div class="table-responsive">
                            <table class="table table-striped" id="categoriesTable">
                                <thead>
                                    <tr>
                                        <th>ID</th>
                                        <th>Name</th>
                                        <th>Description</th>
                                        <th>Status</th>
                                        <th>Actions</th>
                                    </tr>
                                </thead>
                                <tbody>
                                    <tr>
                                        <td colspan="5" class="text-center">
                                            <div class="spinner-border" role="status">
                                                <span class="visually-hidden">Loading...</span>
                                            </div>
                                        </td>
                                    </tr>
                                </tbody>
                            </table>
                        </div>
                        
                        <nav aria-label="Categories pagination">
                            <ul class="pagination justify-content-center" id="categoriesPagination">
                            </ul>
                        </nav>
                    </div>
                </div>
            </div>
        `;
        
        contentArea.innerHTML = categoriesHTML;
        
        // Initialize category manager
        window.categoryManager = new CategoryManager();
        
    } catch (error) {
        contentArea.innerHTML = showError('Failed to load categories: ' + error.message);
    }
}

function showChecklistPoints() {
    setActiveMenuItem('Checklist Points');
    
    const contentArea = document.getElementById('content-area');
    contentArea.innerHTML = `
        <div class="fade-in">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h2><i class="fas fa-check-square me-2"></i>Checklist Points</h2>
                <button class="btn btn-primary">
                    <i class="fas fa-plus me-2"></i>Add Point
                </button>
            </div>
            
            <div class="card">
                <div class="card-header">
                    <h5><i class="fas fa-list me-2"></i>All Checklist Points</h5>
                </div>
                <div class="card-body">
                    <div class="text-center py-5">
                        <i class="fas fa-check-square fa-3x text-muted mb-3"></i>
                        <p class="text-muted">Checklist points management will be implemented here</p>
                        <p class="text-muted">Features: Create individual checklist items with scoring</p>
                    </div>
                </div>
            </div>
        </div>
    `;
}

async function showReports() {
    setActiveMenuItem('Reports');
    
    const contentArea = document.getElementById('content-area');
    contentArea.innerHTML = `
        <div class="fade-in">
            <div class="d-flex justify-content-between align-items-center mb-4">
                <h2><i class="fas fa-chart-bar me-2"></i>Visit Reports</h2>
                <div class="btn-group">
                    <button id="export-xlsx-btn" class="btn btn-success">
                        <i class="fas fa-file-excel me-2"></i>Export to XLSX
                    </button>
                    <button id="export-pdf-btn" class="btn btn-danger">
                        <i class="fas fa-file-pdf me-2"></i>Export to PDF
                    </button>
                </div>
            </div>

            <!-- Filter Section -->
            <div class="card mb-4">
                <div class="card-header bg-primary text-white">
                    <h5><i class="fas fa-filter me-2"></i>Report Filters</h5>
                </div>
                <div class="card-body">
                    <div class="row g-3">
                        <div class="col-md-3">
                            <label for="filter-outlet" class="form-label">Outlet</label>
                            <select id="filter-outlet" class="form-select">
                                <option value="">All Outlets</option>
                            </select>
                        </div>
                        <div class="col-md-3">
                            <label for="filter-division" class="form-label">Division</label>
                            <select id="filter-division" class="form-select">
                                <option value="">All Divisions</option>
                            </select>
                        </div>
                        <div class="col-md-2">
                            <label for="filter-date-from" class="form-label">Date From</label>
                            <input type="date" id="filter-date-from" class="form-control">
                        </div>
                        <div class="col-md-2">
                            <label for="filter-date-to" class="form-label">Date To</label>
                            <input type="date" id="filter-date-to" class="form-control">
                        </div>
                        <div class="col-md-2 d-flex align-items-end">
                            <button id="apply-filter-btn" class="btn btn-primary w-100">
                                <i class="fas fa-search me-2"></i>Apply Filter
                            </button>
                        </div>
                    </div>
                    <div class="row mt-3">
                        <div class="col-12">
                            <div class="btn-group w-100" role="group">
                                <button id="generate-by-outlet-btn" class="btn btn-outline-info">
                                    <i class="fas fa-store me-2"></i>Generate Report by Outlet
                                </button>
                                <button id="generate-by-division-btn" class="btn btn-outline-warning">
                                    <i class="fas fa-building me-2"></i>Generate Report by Division
                                </button>
                                <button id="reset-filter-btn" class="btn btn-outline-secondary">
                                    <i class="fas fa-redo me-2"></i>Reset Filter
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            
            <div class="card mb-4">
                <div class="card-header">
                    <h5><i class="fas fa-list me-2"></i>All Visits</h5>
                    <small class="text-muted" id="filter-info">Showing all visits</small>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-striped" id="audits-table">
                            <thead>
                                <tr>
                                    <th>ID</th>
                                    <th>Outlet</th>
                                    <th>Auditor</th>
                                    <th>Division</th>
                                    <th>Visit Date</th>
                                    <th>Status</th>
                                    <th>Score</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr><td colspan="7" class="text-center">Loading...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>

            <div class="card">
                <div class="card-header">
                    <h5><i class="fas fa-exclamation-triangle me-2"></i>Visit Findings (NOK)</h5>
                    <small class="text-muted">Checklist items yang diberi tanda silang (✗)</small>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-striped" id="findings-table">
                            <thead>
                                <tr>
                                    <th>Outlet</th>
                                    <th>Category</th>
                                    <th>Checklist Point</th>
                                    <th>Date</th>
                                    <th>Photos</th>
                                    <th>Repeat Count</th>
                                </tr>
                            </thead>
                            <tbody>
                                <tr><td colspan="6" class="text-center">Loading...</td></tr>
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        </div>
    `;

    // Load outlets for filter dropdown
    try {
        const outletsResponse = await API.get('/outlets.php?limit=1000');
        const outletSelect = document.getElementById('filter-outlet');
        if (outletsResponse.success && outletsResponse.data && outletsResponse.data.data) {
            outletsResponse.data.data.forEach(outlet => {
                const option = document.createElement('option');
                option.value = outlet.id;
                option.textContent = outlet.name;
                outletSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading outlets:', error);
    }

    // Load divisions for filter dropdown (from visits data)
    try {
        const divisionsResponse = await API.get('/visit-reports.php?divisions=true');
        const divisionSelect = document.getElementById('filter-division');
        if (divisionsResponse.success && divisionsResponse.data.data) {
            const divisions = [...new Set(divisionsResponse.data.data.map(d => d.division_name).filter(d => d))];
            divisions.forEach(division => {
                const option = document.createElement('option');
                option.value = division;
                option.textContent = division;
                divisionSelect.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading divisions:', error);
    }

    // Set default date range (last 30 days)
    const today = new Date();
    const thirtyDaysAgo = new Date(today);
    thirtyDaysAgo.setDate(today.getDate() - 30);
    document.getElementById('filter-date-to').valueAsDate = today;
    document.getElementById('filter-date-from').valueAsDate = thirtyDaysAgo;

    // Function to load visits with filters
    async function loadVisitsWithFilter() {
        const outlet = document.getElementById('filter-outlet').value;
        const division = document.getElementById('filter-division').value;
        const dateFrom = document.getElementById('filter-date-from').value;
        const dateTo = document.getElementById('filter-date-to').value;

        let url = '/visit-reports.php?';
        const params = [];
        if (outlet) params.push(`outlet_id=${outlet}`);
        if (division) params.push(`division=${encodeURIComponent(division)}`);
        if (dateFrom) params.push(`date_from=${dateFrom}`);
        if (dateTo) params.push(`date_to=${dateTo}`);
        url += params.join('&');

        // Update filter info
        let filterText = 'Showing ';
        if (outlet || division || dateFrom || dateTo) {
            const filters = [];
            if (outlet) {
                const selectedOutlet = document.getElementById('filter-outlet').selectedOptions[0].text;
                filters.push(`Outlet: ${selectedOutlet}`);
            }
            if (division) filters.push(`Division: ${division}`);
            if (dateFrom) filters.push(`From: ${dateFrom}`);
            if (dateTo) filters.push(`To: ${dateTo}`);
            filterText += filters.join(' | ');
        } else {
            filterText += 'all visits';
        }
        document.getElementById('filter-info').textContent = filterText;

        return API.get(url);
    }

    // Function to load findings with filters
    async function loadFindingsWithFilter() {
        const outlet = document.getElementById('filter-outlet').value;
        const division = document.getElementById('filter-division').value;
        const dateFrom = document.getElementById('filter-date-from').value;
        const dateTo = document.getElementById('filter-date-to').value;

        let url = '/visit-reports.php?findings=true';
        const params = [];
        if (outlet) params.push(`outlet_id=${outlet}`);
        if (division) params.push(`division=${encodeURIComponent(division)}`);
        if (dateFrom) params.push(`date_from=${dateFrom}`);
        if (dateTo) params.push(`date_to=${dateTo}`);
        if (params.length > 0) {
            url += '&' + params.join('&');
        }

        const response = await API.get(url);
        displayFindings(response);
    }

    // Apply filter button
    document.getElementById('apply-filter-btn').addEventListener('click', async () => {
        try {
            const response = await loadVisitsWithFilter();
            displayVisits(response);
            await loadFindingsWithFilter();
        } catch (error) {
            console.error('Error applying filter:', error);
            Swal.fire('Error', 'Failed to apply filter', 'error');
        }
    });

    // Reset filter button
    document.getElementById('reset-filter-btn').addEventListener('click', () => {
        document.getElementById('filter-outlet').value = '';
        document.getElementById('filter-division').value = '';
        const today = new Date();
        const thirtyDaysAgo = new Date(today);
        thirtyDaysAgo.setDate(today.getDate() - 30);
        document.getElementById('filter-date-to').valueAsDate = today;
        document.getElementById('filter-date-from').valueAsDate = thirtyDaysAgo;
        document.getElementById('apply-filter-btn').click();
    });

    // Generate report by outlet
    document.getElementById('generate-by-outlet-btn').addEventListener('click', async () => {
        try {
            Swal.fire({
                title: 'Generating Report by Outlet',
                text: 'Please wait...',
                allowOutsideClick: false,
                didOpen: () => { Swal.showLoading(); }
            });
            
            await generateReportByOutlet();
            
            Swal.close();
            Swal.fire('Success', 'Report generated successfully!', 'success');
        } catch (error) {
            Swal.fire('Error', error.message, 'error');
        }
    });

    // Generate report by division
    document.getElementById('generate-by-division-btn').addEventListener('click', async () => {
        try {
            Swal.fire({
                title: 'Generating Report by Division',
                text: 'Please wait...',
                allowOutsideClick: false,
                didOpen: () => { Swal.showLoading(); }
            });
            
            await generateReportByDivision();
            
            Swal.close();
            Swal.fire('Success', 'Report generated successfully!', 'success');
        } catch (error) {
            Swal.fire('Error', error.message, 'error');
        }
    });

    // Function to display visits
    function displayVisits(response) {
        console.log('displayVisits called with response:', response);
        const tableBody = document.querySelector('#audits-table tbody');
        if (response.success && response.data.data && response.data.data.length > 0) {
            const visits = response.data.data;
            tableBody.innerHTML = ''; // Clear loading indicator
            visits.forEach(visit => {
                const visitDate = new Date(visit.visit_date).toLocaleDateString('id-ID', {
                    year: 'numeric',
                    month: 'short',
                    day: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit'
                });
                
                const statusBadge = {
                    'completed': 'bg-success',
                    'in_progress': 'bg-warning',
                    'scheduled': 'bg-info',
                    'cancelled': 'bg-danger'
                }[visit.status] || 'bg-secondary';
                
                const row = `
                    <tr style="cursor: pointer;" class="visit-row" data-visit-id="${visit.id}" data-outlet="${visit.outlet_name}" data-date="${visitDate}">
                        <td>${visit.id}</td>
                        <td>${visit.outlet_name || 'N/A'}</td>
                        <td>${visit.auditor_name || 'N/A'}</td>
                        <td>${visit.division_name || 'N/A'}</td>
                        <td>${visitDate}</td>
                        <td><span class="badge ${statusBadge}">${visit.status}</span></td>
                        <td>
                            ${visit.score}%
                            <br>
                            <small class="text-muted">
                                ✓${visit.ok_count} ✗${visit.not_ok_count} N/A${visit.na_count}
                            </small>
                        </td>
                    </tr>
                `;
                tableBody.innerHTML += row;
            });
            
            // Add click event listeners to visit rows
            document.querySelectorAll('.visit-row').forEach(row => {
                row.addEventListener('click', function() {
                    const visitId = this.dataset.visitId;
                    const outlet = this.dataset.outlet;
                    const date = this.dataset.date;
                    showVisitDetail(visitId, outlet, date);
                });
            });
        } else {
            tableBody.innerHTML = '<tr><td colspan="7" class="text-center">No visits found.</td></tr>';
        }
    }

    // Initial load of visits
    try {
        const response = await loadVisitsWithFilter();
        displayVisits(response);
    } catch (error) {
        console.error('Error loading visits:', error);
        const tableBody = document.querySelector('#audits-table tbody');
        tableBody.innerHTML = `<tr><td colspan="7" class="text-center text-danger">Failed to load visits: ${error.message}</td></tr>`;
    }

    // Function to display findings
    function displayFindings(response) {
        console.log('displayFindings called with response:', response);
        const tableBody = document.querySelector('#findings-table tbody');
        if (response.success && response.data.data && response.data.data.length > 0) {
            const findings = response.data.data;

            // Process findings to count repeats
            const findingsMap = {};
            findings.forEach(finding => {
                const key = `${finding.outlet_id}-${finding.checklist_point_id}`;
                if (!findingsMap[key]) {
                    findingsMap[key] = {
                        outlet_name: finding.outlet_name,
                        category_name: finding.category_name,
                        checklist_point_question: finding.checklist_point_question,
                        dates: [],
                        count: 0,
                        photo_count: 0
                    };
                }
                findingsMap[key].dates.push(finding.visit_date);
                findingsMap[key].count++;
                findingsMap[key].photo_count += parseInt(finding.photo_count || 0);
            });

            tableBody.innerHTML = ''; // Clear loading indicator
            for (const key in findingsMap) {
                const finding = findingsMap[key];
                const lastDate = new Date(finding.dates.sort().reverse()[0]).toLocaleDateString('id-ID');
                const isRepeat = finding.count > 1;
                const hasPhoto = finding.photo_count > 0;

                const row = `
                    <tr class="${isRepeat ? 'table-danger' : ''} ${hasPhoto ? 'finding-row-clickable' : ''}" 
                        style="${hasPhoto ? 'cursor: pointer;' : ''}"
                        ${hasPhoto ? `data-outlet="${finding.outlet_name}" data-category="${finding.category_name}" data-question="${finding.checklist_point_question}"` : ''}>
                        <td>${finding.outlet_name}</td>
                        <td><span class="badge bg-secondary">${finding.category_name}</span></td>
                        <td>${finding.checklist_point_question}</td>
                        <td>${lastDate}</td>
                        <td>
                            ${hasPhoto ? `<i class="fas fa-camera text-success"></i> ${finding.photo_count} <small class="text-muted">(click to view)</small>` : '<span class="text-muted">-</span>'}
                        </td>
                        <td>
                            ${finding.count}
                            ${isRepeat ? '<span class="badge bg-danger ms-2">Repeat</span>' : ''}
                        </td>
                    </tr>
                `;
                tableBody.innerHTML += row;
            }
            
            // Add click event listeners to findings with photos
            document.querySelectorAll('.finding-row-clickable').forEach(row => {
                row.addEventListener('click', function() {
                    const outlet = this.dataset.outlet;
                    const category = this.dataset.category;
                    const question = this.dataset.question;
                    showFindingPhotos(findings, outlet, category, question);
                });
            });
        } else {
            tableBody.innerHTML = '<tr><td colspan="6" class="text-center">No findings found.</td></tr>';
        }
    }

    // Fetch and display findings
    try {
        await loadFindingsWithFilter();
    } catch (error) {
        console.error('Error loading findings:', error);
        const tableBody = document.querySelector('#findings-table tbody');
        tableBody.innerHTML = `<tr><td colspan="6" class="text-center text-danger">Failed to load findings: ${error.message}</td></tr>`;
    }

    // Add event listeners for export buttons
    document.getElementById('export-xlsx-btn').addEventListener('click', async () => {
        try {
            Swal.fire({
                title: 'Exporting...',
                text: 'Please wait while we prepare your Excel file with photos',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            await exportToExcelWithPhotos();
            
            Swal.close();
            Swal.fire({
                icon: 'success',
                title: 'Export Complete!',
                text: 'Excel file has been downloaded',
                timer: 2000,
                showConfirmButton: false
            });
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Export Failed',
                text: error.message
            });
        }
    });

    document.getElementById('export-pdf-btn').addEventListener('click', async () => {
        try {
            Swal.fire({
                title: 'Exporting...',
                text: 'Please wait while we prepare your PDF file with photos',
                allowOutsideClick: false,
                didOpen: () => {
                    Swal.showLoading();
                }
            });

            await exportToPDFWithPhotos();
            
            Swal.close();
            Swal.fire({
                icon: 'success',
                title: 'Export Complete!',
                text: 'PDF file has been downloaded',
                timer: 2000,
                showConfirmButton: false
            });
        } catch (error) {
            Swal.fire({
                icon: 'error',
                title: 'Export Failed',
                text: error.message
            });
        }
    });
}

/**
 * Generate Report by Outlet with NOK Details and Photos
 */
async function generateReportByOutlet() {
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;

    // Get all visits
    let url = '/visit-reports.php?';
    const params = [];
    if (dateFrom) params.push(`date_from=${dateFrom}`);
    if (dateTo) params.push(`date_to=${dateTo}`);
    url += params.join('&');

    const response = await API.get(url);
    if (!response.success || !response.data.data.length) {
        throw new Error('No data found for the selected period');
    }

    const visits = response.data.data;
    
    // Get findings (NOK) data
    const findingsResponse = await API.get(url.replace('visit-reports.php', 'visit-reports.php') + '&findings=true');
    const findings = findingsResponse.success ? findingsResponse.data.data : [];
    
    // Group visits by outlet
    const outletGroups = {};
    visits.forEach(visit => {
        const outletName = visit.outlet_name || 'Unknown';
        if (!outletGroups[outletName]) {
            outletGroups[outletName] = {
                visits: [],
                findings: []
            };
        }
        outletGroups[outletName].visits.push(visit);
    });
    
    // Group findings by outlet
    findings.forEach(finding => {
        const outletName = finding.outlet_name || 'Unknown';
        if (outletGroups[outletName]) {
            outletGroups[outletName].findings.push(finding);
        }
    });

    // Create workbook
    const ExcelJS = window.ExcelJS;
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'TND System';
    workbook.created = new Date();

    // Process each outlet
    for (const outletName of Object.keys(outletGroups).sort()) {
        const outletData = outletGroups[outletName];
        const outletVisits = outletData.visits;
        const outletFindings = outletData.findings;

        // Create sheet for this outlet
        const sheetName = outletName.substring(0, 30); // Excel sheet name limit
        const outletSheet = workbook.addWorksheet(sheetName);
        
        // Add outlet header
        outletSheet.mergeCells('A1:G1');
        const titleRow = outletSheet.getRow(1);
        titleRow.getCell(1).value = `OUTLET: ${outletName}`;
        titleRow.getCell(1).font = { bold: true, size: 14, color: { argb: 'FFFFFFFF' } };
        titleRow.getCell(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FF2C3E50' }
        };
        titleRow.getCell(1).alignment = { vertical: 'middle', horizontal: 'center' };
        titleRow.height = 25;

        let currentRow = 2;

        // Process each visit
        for (const visit of outletVisits) {
            // Visit header
            currentRow++;
            outletSheet.mergeCells(`A${currentRow}:G${currentRow}`);
            const visitRow = outletSheet.getRow(currentRow);
            const visitDate = new Date(visit.visit_date).toLocaleString('id-ID');
            visitRow.getCell(1).value = `Visit #${visit.id} - ${visitDate} - Auditor: ${visit.auditor_name} - Score: ${visit.score}%`;
            visitRow.getCell(1).font = { bold: true, size: 11 };
            visitRow.getCell(1).fill = {
                type: 'pattern',
                pattern: 'solid',
                fgColor: { argb: 'FFE8F4F8' }
            };
            visitRow.height = 20;
            currentRow++;

            // Get visit details (checklist responses and photos)
            try {
                const visitDetail = await API.get(`/visit-detail.php?visit_id=${visit.id}`);
                console.log('Visit detail response:', visitDetail);
                
                if (visitDetail.success && visitDetail.data) {
                    // API returns: {success: true, data: {visit, responses, photos}}
                    const responses = visitDetail.data.responses || [];
                    const photos = visitDetail.data.photos || [];
                    
                    console.log(`Visit ${visit.id}: ${responses.length} responses, ${photos.length} photos`);
                    
                    if (responses.length > 0) {
                        // Table header for all checklist items
                        const headerRow = outletSheet.getRow(currentRow);
                        headerRow.getCell(1).value = 'Category';
                        headerRow.getCell(2).value = 'Checklist Point';
                        headerRow.getCell(3).value = 'Status';
                        headerRow.getCell(4).value = 'Issue/Notes';
                        headerRow.getCell(5).value = 'Photo';
                        
                        headerRow.font = { bold: true, color: { argb: 'FFFFFFFF' } };
                        headerRow.fill = {
                            type: 'pattern',
                            pattern: 'solid',
                            fgColor: { argb: 'FF3498DB' }
                        };
                        headerRow.alignment = { vertical: 'middle', horizontal: 'center' };
                        headerRow.height = 20;
                        
                        // Set column widths
                        outletSheet.getColumn(1).width = 20;
                        outletSheet.getColumn(2).width = 40;
                        outletSheet.getColumn(3).width = 12;
                        outletSheet.getColumn(4).width = 30;
                        outletSheet.getColumn(5).width = 15;
                        
                        currentRow++;
                        
                        // Add all checklist items
                        for (const item of responses) {
                            const itemRow = outletSheet.getRow(currentRow);
                            itemRow.getCell(1).value = item.category_name || 'N/A';
                            itemRow.getCell(2).value = item.question || 'N/A';
                            
                            // Normalize response value
                            const normalizedResponse = (item.response || '').toLowerCase().replace(/ /g, '_');
                            
                            // Status with icon
                            let statusText = '';
                            let statusColor = 'FF000000';
                            if (normalizedResponse === 'ok') {
                                statusText = '✓';
                                statusColor = 'FF27AE60'; // Green
                            } else if (normalizedResponse === 'not_ok') {
                                statusText = '✗';
                                statusColor = 'FFE74C3C'; // Red
                            } else {
                                statusText = '- N/A';
                                statusColor = 'FF95A5A6'; // Gray
                            }
                            
                            itemRow.getCell(3).value = statusText;
                            itemRow.getCell(3).font = { color: { argb: statusColor }, bold: true };
                            itemRow.getCell(3).alignment = { horizontal: 'center' };
                            
                            itemRow.getCell(4).value = item.notes || '-';
                            
                            // Photos only for NOK items
                            if (normalizedResponse === 'not_ok') {
                                // Find photos for this checklist item
                                const itemPhotos = photos.filter(p => p.checklist_item_id == item.checklist_item_id);
                                if (itemPhotos.length > 0) {
                                    itemRow.getCell(5).value = `${itemPhotos.length} photo(s)`;
                                    // Embed each photo in the same cell (E/5), ditumpuk vertikal
                                    let photoIndex = 0;
                                    for (const photo of itemPhotos.slice(0, 3)) { // Max 3 photos per cell
                                        try {
                                            const photoPath = photo.photo_path;
                                            const fullPhotoUrl = window.location.origin + '/tnd_system/tnd_system/backend-web/' + photoPath;
                                            console.log('Fetching photo:', fullPhotoUrl);
                                            const photoResponse = await fetch(fullPhotoUrl, {
                                                mode: 'cors',
                                                credentials: 'include'
                                            });
                                            if (!photoResponse.ok) {
                                                console.error('Photo fetch failed:', photoResponse.status, photoResponse.statusText);
                                                continue;
                                            }
                                            const photoBlob = await photoResponse.blob();
                                            const base64data = await new Promise((resolve, reject) => {
                                                const reader = new FileReader();
                                                reader.onloadend = () => {
                                                    const result = reader.result.split(',')[1];
                                                    resolve(result);
                                                };
                                                reader.onerror = reject;
                                                reader.readAsDataURL(photoBlob);
                                            });
                                            const imageId = workbook.addImage({
                                                base64: base64data,
                                                extension: photoPath.toLowerCase().includes('.png') ? 'png' : 'jpeg',
                                            });
                                            // Embed persis di cell E (col: 4, row: currentRow-1), offset vertikal jika lebih dari 1 foto
                                            const cellCol = 4; // kolom E (0-based)
                                            const cellRow = currentRow - 1 + (photoIndex * 0.33); // offset vertikal jika lebih dari 1 foto
                                            outletSheet.addImage(imageId, {
                                                tl: { col: cellCol, row: cellRow },
                                                br: { col: cellCol + 1, row: cellRow + 0.33 },
                                                editAs: 'oneCell'
                                            });
                                            photoIndex++;
                                        } catch (photoError) {
                                            console.error('Error loading photo:', photoError);
                                        }
                                    }
                                    itemRow.height = 80; // Increase row height for photos
                                } else {
                                    itemRow.getCell(5).value = 'No photo';
                                    itemRow.height = 20;
                                }
                            } else {
                                // OK or N/A - no photo
                                itemRow.getCell(5).value = '-';
                                itemRow.height = 20;
                            }
                            
                            // Style row
                            itemRow.alignment = { vertical: 'top', wrapText: true };
                            itemRow.border = {
                                top: { style: 'thin' },
                                left: { style: 'thin' },
                                bottom: { style: 'thin' },
                                right: { style: 'thin' }
                            };
                            
                            currentRow++;
                        }
                    } else {
                        // No responses
                        const noDataRow = outletSheet.getRow(currentRow);
                        outletSheet.mergeCells(`A${currentRow}:G${currentRow}`);
                        noDataRow.getCell(1).value = 'No checklist data';
                        noDataRow.getCell(1).font = { color: { argb: 'FF95A5A6' }, italic: true };
                        noDataRow.height = 20;
                        currentRow++;
                    }
                }
            } catch (error) {
                console.error('Error loading visit detail:', error);
                const errorRow = outletSheet.getRow(currentRow);
                outletSheet.mergeCells(`A${currentRow}:G${currentRow}`);
                errorRow.getCell(1).value = `Error: ${error.message}`;
                errorRow.getCell(1).font = { color: { argb: 'FFE74C3C' } };
                currentRow++;
            }
            
            currentRow++; // Empty row between visits
        }
    }

    // Save file
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileUrl = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = fileUrl;
    link.download = `Visit_Report_by_Outlet_Detail_${new Date().toISOString().split('T')[0]}.xlsx`;
    link.click();
    window.URL.revokeObjectURL(fileUrl);
}

/**
 * Generate Report by Division
 */
async function generateReportByDivision() {
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;

    // Get all visits
    let url = '/visit-reports.php?';
    const params = [];
    if (dateFrom) params.push(`date_from=${dateFrom}`);
    if (dateTo) params.push(`date_to=${dateTo}`);
    url += params.join('&');

    const response = await API.get(url);
    if (!response.success || !response.data.data.length) {
        throw new Error('No data found for the selected period');
    }

    const visits = response.data.data;
    
    // Group visits by division
    const divisionGroups = {};
    visits.forEach(visit => {
        const divisionName = visit.division_name || 'Unknown';
        if (!divisionGroups[divisionName]) {
            divisionGroups[divisionName] = [];
        }
        divisionGroups[divisionName].push(visit);
    });

    // Create workbook
    const ExcelJS = window.ExcelJS;
    const workbook = new ExcelJS.Workbook();
    workbook.creator = 'TND System';
    workbook.created = new Date();

    // Create summary sheet
    const summarySheet = workbook.addWorksheet('Summary');
    summarySheet.columns = [
        { header: 'Division', key: 'division', width: 30 },
        { header: 'Total Visits', key: 'total', width: 15 },
        { header: 'Avg Score', key: 'avgScore', width: 15 },
        { header: 'Total OK', key: 'totalOk', width: 12 },
        { header: 'Total NOK', key: 'totalNok', width: 12 },
        { header: 'Total N/A', key: 'totalNa', width: 12 }
    ];

    // Style header
    summarySheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    summarySheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFF39C12' }
    };
    summarySheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

    // Add summary data and create individual sheets
    Object.keys(divisionGroups).sort().forEach(divisionName => {
        const divisionVisits = divisionGroups[divisionName];
        const totalVisits = divisionVisits.length;
        const avgScore = (divisionVisits.reduce((sum, v) => sum + parseFloat(v.score || 0), 0) / totalVisits).toFixed(2);
        const totalOk = divisionVisits.reduce((sum, v) => sum + parseInt(v.ok_count || 0), 0);
        const totalNok = divisionVisits.reduce((sum, v) => sum + parseInt(v.not_ok_count || 0), 0);
        const totalNa = divisionVisits.reduce((sum, v) => sum + parseInt(v.na_count || 0), 0);

        summarySheet.addRow({
            division: divisionName,
            total: totalVisits,
            avgScore: avgScore + '%',
            totalOk: totalOk,
            totalNok: totalNok,
            totalNa: totalNa
        });

        // Create individual division sheet
        const sheetName = divisionName.substring(0, 30); // Excel sheet name limit
        const divisionSheet = workbook.addWorksheet(sheetName);
        
        divisionSheet.columns = [
            { header: 'Visit ID', key: 'id', width: 10 },
            { header: 'Outlet', key: 'outlet', width: 25 },
            { header: 'Auditor', key: 'auditor', width: 20 },
            { header: 'Visit Date', key: 'date', width: 20 },
            { header: 'Status', key: 'status', width: 15 },
            { header: 'Score', key: 'score', width: 10 },
            { header: 'OK', key: 'ok', width: 8 },
            { header: 'NOK', key: 'nok', width: 8 },
            { header: 'N/A', key: 'na', width: 8 }
        ];

        // Style header
        divisionSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
        divisionSheet.getRow(1).fill = {
            type: 'pattern',
            pattern: 'solid',
            fgColor: { argb: 'FFE74C3C' }
        };
        divisionSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };

        // Add division data
        divisionVisits.forEach(visit => {
            const visitDate = new Date(visit.visit_date).toLocaleString('id-ID');
            divisionSheet.addRow({
                id: visit.id,
                outlet: visit.outlet_name || 'N/A',
                auditor: visit.auditor_name || 'N/A',
                date: visitDate,
                status: visit.status,
                score: visit.score + '%',
                ok: visit.ok_count,
                nok: visit.not_ok_count,
                na: visit.na_count
            });
        });
    });

    // Save file
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const fileUrl = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = fileUrl;
    link.download = `Visit_Report_by_Division_${new Date().toISOString().split('T')[0]}.xlsx`;
    link.click();
    window.URL.revokeObjectURL(fileUrl);
}

/**
 * Export to Excel with Photos using ExcelJS
 */
async function exportToExcelWithPhotos() {
    const ExcelJS = window.ExcelJS;
    const workbook = new ExcelJS.Workbook();
    
    workbook.creator = 'TND System';
    workbook.created = new Date();
    
    // Build URL with current filters
    const outlet = document.getElementById('filter-outlet').value;
    const division = document.getElementById('filter-division').value;
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;
    
    let visitUrl = '/visit-reports.php?';
    let findingsUrl = '/visit-reports.php?findings=true';
    const params = [];
    if (outlet) params.push(`outlet_id=${outlet}`);
    if (division) params.push(`division=${encodeURIComponent(division)}`);
    if (dateFrom) params.push(`date_from=${dateFrom}`);
    if (dateTo) params.push(`date_to=${dateTo}`);
    
    if (params.length > 0) {
        visitUrl += params.join('&');
        findingsUrl += '&' + params.join('&');
    }
    
    // Get visit data
    const visitResponse = await API.get(visitUrl);
    const visits = visitResponse.data.data;
    
    // Get findings data
    const findingsResponse = await API.get(findingsUrl);
    const findings = findingsResponse.data.data;
    
    // Sheet 1: All Visits
    const visitsSheet = workbook.addWorksheet('All Visits', {
        views: [{ state: 'frozen', ySplit: 1 }]
    });
    
    // Define columns
    visitsSheet.columns = [
        { header: 'ID', key: 'id', width: 8 },
        { header: 'Outlet', key: 'outlet', width: 25 },
        { header: 'Auditor', key: 'auditor', width: 20 },
        { header: 'Division', key: 'division', width: 20 },
        { header: 'Visit Date', key: 'date', width: 20 },
        { header: 'Status', key: 'status', width: 12 },
        { header: 'Score', key: 'score', width: 10 },
        { header: 'OK', key: 'ok', width: 8 },
        { header: 'NOK', key: 'nok', width: 8 },
        { header: 'N/A', key: 'na', width: 8 }
    ];
    
    // Style header
    visitsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    visitsSheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FF16A085' }
    };
    visitsSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
    
    // Add data
    visits.forEach(visit => {
        const visitDate = new Date(visit.visit_date).toLocaleString('id-ID', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        
        visitsSheet.addRow({
            id: visit.id,
            outlet: visit.outlet_name || 'N/A',
            auditor: visit.auditor_name || 'N/A',
            division: visit.division_name || 'N/A',
            date: visitDate,
            status: visit.status,
            score: visit.score + '%',
            ok: visit.ok_count,
            nok: visit.not_ok_count,
            na: visit.na_count
        });
    });
    
    // Sheet 2: Findings with Photos
    const findingsSheet = workbook.addWorksheet('Findings with Photos', {
        views: [{ state: 'frozen', ySplit: 1 }]
    });
    
    findingsSheet.columns = [
        { header: 'Outlet', key: 'outlet', width: 25 },
        { header: 'Category', key: 'category', width: 20 },
        { header: 'Checklist Point', key: 'point', width: 40 },
        { header: 'Date', key: 'date', width: 20 },
        { header: 'Photos', key: 'photos', width: 60 }
    ];
    
    // Style header
    findingsSheet.getRow(1).font = { bold: true, color: { argb: 'FFFFFFFF' } };
    findingsSheet.getRow(1).fill = {
        type: 'pattern',
        pattern: 'solid',
        fgColor: { argb: 'FFE74C3C' }
    };
    findingsSheet.getRow(1).alignment = { vertical: 'middle', horizontal: 'center' };
    
    // Set default row height for images
    findingsSheet.properties.defaultRowHeight = 120;
    
    // Add findings with photos
    let rowIndex = 2;
    for (const finding of findings) {
        const findingDate = new Date(finding.visit_date).toLocaleDateString('id-ID', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
        
        const row = findingsSheet.addRow({
            outlet: finding.outlet_name,
            category: finding.category_name,
            point: finding.checklist_point_question,
            date: findingDate,
            photos: finding.photo_count > 0 ? `${finding.photo_count} photo(s)` : 'No photos'
        });
        
        row.alignment = { vertical: 'top', wrapText: true };
        
        // Fetch and add photos if available
        if (finding.photo_count > 0) {
            try {
                const photosResponse = await API.get(`/finding-photos.php?outlet=${encodeURIComponent(finding.outlet_name)}&question=${encodeURIComponent(finding.checklist_point_question)}`);
                
                if (photosResponse.success && photosResponse.data.data.length > 0) {
                    const photos = photosResponse.data.data;
                    let colOffset = 0;
                    
                    for (let i = 0; i < Math.min(photos.length, 3); i++) {
                        const photo = photos[i];
                        // Use photo_url from backend instead of constructing path
                        const photoUrl = photo.photo_url || `${API.baseURL}/${photo.photo_path}`;
                        
                        try {
                            // Fetch image as blob
                            const response = await fetch(photoUrl);
                            const blob = await response.blob();
                            const arrayBuffer = await blob.arrayBuffer();
                            
                            // Determine image extension
                            const ext = photo.photo_path.split('.').pop().toLowerCase();
                            const imageId = workbook.addImage({
                                buffer: arrayBuffer,
                                extension: ext === 'jpg' ? 'jpeg' : ext
                            });
                            
                            // Add image to cell (Photos column + offset)
                            findingsSheet.addImage(imageId, {
                                tl: { col: 4 + colOffset * 0.33, row: rowIndex - 1 + 0.1 },
                                ext: { width: 100, height: 100 }
                            });
                            
                            colOffset++;
                        } catch (imgError) {
                            console.error('Failed to add image:', imgError);
                        }
                    }
                    
                    row.height = 120;
                }
            } catch (photoError) {
                console.error('Failed to fetch photos:', photoError);
            }
        }
        
        rowIndex++;
    }
    
    // Generate and download
    const buffer = await workbook.xlsx.writeBuffer();
    const blob = new Blob([buffer], { type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `Visit_Report_${new Date().toISOString().split('T')[0]}.xlsx`;
    a.click();
    window.URL.revokeObjectURL(url);
}

/**
 * Export to PDF with Photos
 */
async function exportToPDFWithPhotos() {
    const { jsPDF } = window.jspdf;
    const doc = new jsPDF();
    
    // Build URL with current filters
    const outlet = document.getElementById('filter-outlet').value;
    const division = document.getElementById('filter-division').value;
    const dateFrom = document.getElementById('filter-date-from').value;
    const dateTo = document.getElementById('filter-date-to').value;
    
    let visitUrl = '/visit-reports.php?';
    let findingsUrl = '/visit-reports.php?findings=true';
    const params = [];
    if (outlet) params.push(`outlet_id=${outlet}`);
    if (division) params.push(`division=${encodeURIComponent(division)}`);
    if (dateFrom) params.push(`date_from=${dateFrom}`);
    if (dateTo) params.push(`date_to=${dateTo}`);
    
    if (params.length > 0) {
        visitUrl += params.join('&');
        findingsUrl += '&' + params.join('&');
    }
    
    // Get data
    const visitResponse = await API.get(visitUrl);
    const visits = visitResponse.data.data;
    
    const findingsResponse = await API.get(findingsUrl);
    const findings = findingsResponse.data.data;
    
    let yPos = 20;
    
    // Title
    doc.setFontSize(20);
    doc.setTextColor(40);
    doc.text('Visit Report', 14, yPos);
    yPos += 10;
    
    // Visits Table
    doc.setFontSize(14);
    doc.text('All Visits', 14, yPos);
    yPos += 5;
    
    const visitsData = visits.map(v => {
        const visitDate = new Date(v.visit_date).toLocaleString('id-ID', {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit'
        });
        return [
            v.id,
            v.outlet_name || 'N/A',
            v.auditor_name || 'N/A',
            visitDate,
            v.status,
            v.score + '%'
        ];
    });
    
    doc.autoTable({
        startY: yPos,
        head: [['ID', 'Outlet', 'Auditor', 'Date', 'Status', 'Score']],
        body: visitsData,
        headStyles: { fillColor: [22, 160, 133] },
        theme: 'striped',
        styles: { fontSize: 8 }
    });
    
    // Add new page for findings
    doc.addPage();
    yPos = 20;
    
    doc.setFontSize(14);
    doc.text('Visit Findings with Photos', 14, yPos);
    yPos += 10;
    
    // Group findings by outlet
    const findingsGrouped = {};
    findings.forEach(f => {
        if (!findingsGrouped[f.outlet_name]) {
            findingsGrouped[f.outlet_name] = [];
        }
        findingsGrouped[f.outlet_name].push(f);
    });
    
    // Process each outlet's findings
    for (const [outlet, outletFindings] of Object.entries(findingsGrouped)) {
        // Check if we need a new page
        if (yPos > 250) {
            doc.addPage();
            yPos = 20;
        }
        
        doc.setFontSize(12);
        doc.setFont(undefined, 'bold');
        doc.text(`Outlet: ${outlet}`, 14, yPos);
        yPos += 7;
        doc.setFont(undefined, 'normal');
        
        for (const finding of outletFindings) {
            // Check space
            if (yPos > 250) {
                doc.addPage();
                yPos = 20;
            }
            
            doc.setFontSize(10);
            doc.text(`• ${finding.category_name}: ${finding.checklist_point_question}`, 14, yPos);
            yPos += 5;
            
            const findingDate = new Date(finding.visit_date).toLocaleDateString('id-ID');
            doc.setFontSize(8);
            doc.setTextColor(100);
            doc.text(`  Date: ${findingDate}`, 14, yPos);
            yPos += 5;
            doc.setTextColor(40);
            
            // Fetch and add photos
            if (finding.photo_count > 0) {
                try {
                    const photosResponse = await API.get(`/finding-photos.php?outlet=${encodeURIComponent(finding.outlet_name)}&question=${encodeURIComponent(finding.checklist_point_question)}`);
                    
                    if (photosResponse.success && photosResponse.data.data.length > 0) {
                        const photos = photosResponse.data.data;
                        let xPos = 14;
                        
                        for (let i = 0; i < Math.min(photos.length, 3); i++) {
                            const photo = photos[i];
                            // Use photo_url from backend instead of constructing path
                            const photoUrl = photo.photo_url || `${API.baseURL}/${photo.photo_path}`;
                            
                            try {
                                // Check if we need new page
                                if (yPos > 220) {
                                    doc.addPage();
                                    yPos = 20;
                                    xPos = 14;
                                }
                                
                                // Add image
                                doc.addImage(photoUrl, 'JPEG', xPos, yPos, 50, 50);
                                xPos += 55;
                                
                                // Move to next row after 3 images
                                if ((i + 1) % 3 === 0) {
                                    yPos += 55;
                                    xPos = 14;
                                }
                            } catch (imgError) {
                                console.error('Failed to add image to PDF:', imgError);
                            }
                        }
                        
                        // Adjust yPos if images were added
                        if (photos.length % 3 !== 0) {
                            yPos += 55;
                        }
                    }
                } catch (photoError) {
                    console.error('Failed to fetch photos for PDF:', photoError);
                }
            }
            
            yPos += 5;
        }
        
        yPos += 5;
    }
    
    // Save PDF
    doc.save(`Visit_Report_${new Date().toISOString().split('T')[0]}.pdf`);
}

async function OLD_exportToExcel() {
    // Old export function - kept for reference
    const wb = XLSX.utils.book_new();

    // Visits sheet
    const auditsTable = document.getElementById('audits-table');
    const auditsSheet = XLSX.utils.table_to_sheet(auditsTable, { sheet: "Visits" });
    XLSX.utils.book_append_sheet(wb, auditsSheet, "All Visits");

    // Findings sheet
    const findingsTable = document.getElementById('findings-table');
    const findingsSheet = XLSX.utils.table_to_sheet(findingsTable, { sheet: "Findings" });
    XLSX.utils.book_append_sheet(wb, findingsSheet, "Visit Findings");

    XLSX.writeFile(wb, "Visit_Report.xlsx");
}

async function OLD_exportToPDF() {
    // Old export function - kept for reference
    const { jsPDF } = jspdf;
    const doc = new jsPDF();
    
    // Visits table
    doc.autoTable({
        html: '#audits-table',
        startY: 20,
        headStyles: { fillColor: [22, 160, 133] },
        didDrawPage: function (data) {
            // Header
            doc.setFontSize(20);
            doc.setTextColor(40);
            doc.text("Visit Report", data.settings.margin.left, 15);
        }
    });

    // Findings table
    doc.autoTable({
        html: '#findings-table',
        headStyles: { fillColor: [22, 160, 133] },
        didDrawPage: function (data) {
            // Header
            doc.setFontSize(16);
            doc.setTextColor(40);
            doc.text("Visit Findings", data.settings.margin.left, data.cursor.y + 15);
        }
    });

    doc.save('Visit_Report.pdf');
}

/**
 * Category Manager Class
 */
class CategoryManager {
    constructor() {
        this.categories = [];
        this.currentPage = 1;
        this.totalPages = 1;
        // Ensure API is available
        if (typeof API === 'undefined') {
            console.error('API class not found. Make sure api.js is loaded.');
            return;
        }
        this.init();
    }

    init() {
        this.loadCategories();
        this.bindEvents();
        this.createCategoryModal();
    }

    bindEvents() {
        document.addEventListener('click', (e) => {
            if (e.target.matches('#addCategoryBtn')) {
                this.showAddModal();
            }
            
            if (e.target.matches('.edit-category-btn')) {
                const id = e.target.dataset.id;
                this.showEditModal(id);
            }
            
            if (e.target.matches('.delete-category-btn')) {
                const id = e.target.dataset.id;
                this.deleteCategory(id);
            }
            
            if (e.target.matches('#saveCategoryBtn')) {
                this.saveCategory();
            }
        });

        const searchInput = document.querySelector('#categorySearch');
        if (searchInput) {
            searchInput.addEventListener('input', (e) => {
                this.searchCategories(e.target.value);
            });
        }
    }

    async loadCategories(search = '') {
        try {
            console.log('Loading categories...'); // Debug log
            const response = await API.get(`/checklist-categories.php?page=${this.currentPage}&limit=10&search=${search}`);
            console.log('Categories response:', response); // Debug log
            
            if (response.success) {
                this.categories = response.data.data;
                this.totalPages = response.data.pagination.pages;
                this.renderCategories();
                this.renderPagination();
            } else {
                throw new Error(response.message || 'Failed to load categories');
            }
        } catch (error) {
            console.error('Error loading categories:', error);
            // Show user-friendly error message
            Swal.fire({
                title: 'Error',
                text: `Failed to load categories: ${error.message}`,
                icon: 'error',
                confirmButtonText: 'OK'
            });
            
            const tbody = document.querySelector('#categoriesTable tbody');
            if (tbody) {
                tbody.innerHTML = `
                    <tr>
                        <td colspan="5" class="text-center text-danger">
                            <i class="fas fa-exclamation-triangle me-2"></i>
                            Failed to load categories: ${error.message}
                        </td>
                    </tr>
                `;
            }
        }
    }

    renderCategories() {
        const tbody = document.querySelector('#categoriesTable tbody');
        if (!tbody) return;

        tbody.innerHTML = '';

        if (this.categories.length === 0) {
            tbody.innerHTML = `
                <tr>
                    <td colspan="5" class="text-center text-muted">
                        <i class="fas fa-inbox me-2"></i>No categories found
                    </td>
                </tr>
            `;
            return;
        }

        this.categories.forEach(category => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td>${category.id}</td>
                <td>${category.name}</td>
                <td class="text-truncate" style="max-width: 300px;" title="${category.description}">
                    ${category.description}  
                </td>
                <td>
                    <span class="badge bg-${category.status === 'active' ? 'success' : 'secondary'}">
                        ${category.status}
                    </span>
                </td>
                <td>
                    <div class="btn-group" role="group">
                        <button class="btn btn-sm btn-outline-primary edit-category-btn" data-id="${category.id}" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-outline-danger delete-category-btn" data-id="${category.id}" title="Delete">
                            <i class="fas fa-trash"></i>
                        </button>
                    </div>
                </td>
            `;
            tbody.appendChild(row);
        });
    }

    renderPagination() {
        const pagination = document.querySelector('#categoriesPagination');
        if (!pagination) return;

        if (this.totalPages <= 1) {
            pagination.innerHTML = '';
            return;
        }

        let html = '';
        
        html += `<li class="page-item ${this.currentPage === 1 ? 'disabled' : ''}">
            <a class="page-link" href="#" data-page="${this.currentPage - 1}">Previous</a>
        </li>`;
        
        for (let i = 1; i <= this.totalPages; i++) {
            html += `<li class="page-item ${i === this.currentPage ? 'active' : ''}">
                <a class="page-link" href="#" data-page="${i}">${i}</a>
            </li>`;
        }
        
        html += `<li class="page-item ${this.currentPage === this.totalPages ? 'disabled' : ''}">
            <a class="page-link" href="#" data-page="${this.currentPage + 1}">Next</a>
        </li>`;
        
        pagination.innerHTML = html;
    }

    createCategoryModal() {
        const existingModal = document.getElementById('categoryModal');
        if (existingModal) {
            existingModal.remove();
        }

        const modalHtml = `
            <div class="modal fade" id="categoryModal" tabindex="-1">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <h5 class="modal-title" id="categoryModalTitle">Add Category</h5>
                            <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                        </div>
                        <div class="modal-body">
                            <form id="categoryForm">
                                <input type="hidden" id="categoryId">
                                <div class="mb-3">
                                    <label for="categoryName" class="form-label">Name *</label>
                                    <input type="text" class="form-control" id="categoryName" required>
                                </div>
                                <div class="mb-3">
                                    <label for="categoryDescription" class="form-label">Description *</label>
                                    <textarea class="form-control" id="categoryDescription" rows="3" required></textarea>
                                </div>
                                <div class="mb-3">
                                    <label for="categoryStatus" class="form-label">Status</label>
                                    <select class="form-control" id="categoryStatus">
                                        <option value="active">Active</option>
                                        <option value="inactive">Inactive</option>
                                    </select>
                                </div>
                            </form>
                        </div>
                        <div class="modal-footer">
                            <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Close</button>
                            <button type="button" class="btn btn-primary" id="saveCategoryBtn">
                                <i class="fas fa-save me-2"></i>Save
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        document.body.insertAdjacentHTML('beforeend', modalHtml);
    }

    showAddModal() {
        document.getElementById('categoryModalTitle').textContent = 'Add Category';
        document.getElementById('categoryForm').reset();
        document.getElementById('categoryId').value = '';
        
        const modal = new bootstrap.Modal(document.getElementById('categoryModal'));
        modal.show();
    }

    async showEditModal(id) {
        try {
            const response = await API.get(`/checklist-categories.php?id=${id}`);
            
            if (response.success) {
                const category = response.data;
                
                document.getElementById('categoryModalTitle').textContent = 'Edit Category';
                document.getElementById('categoryId').value = category.id;
                document.getElementById('categoryName').value = category.name;
                document.getElementById('categoryDescription').value = category.description;
                document.getElementById('categoryStatus').value = category.status;
                
                const modal = new bootstrap.Modal(document.getElementById('categoryModal'));
                modal.show();
            } else {
                Swal.fire('Error', response.message || 'Failed to load category data', 'error');
            }
        } catch (error) {
            console.error('Error loading category:', error);
            Swal.fire('Error', 'Failed to load category data', 'error');
        }
    }

    async saveCategory() {
        const form = document.getElementById('categoryForm');
        if (!form.checkValidity()) {
            form.reportValidity();
            return;
        }

        const categoryData = {
            name: document.getElementById('categoryName').value,
            description: document.getElementById('categoryDescription').value,
            status: document.getElementById('categoryStatus').value
        };

        const id = document.getElementById('categoryId').value;

        try {
            let response;
            if (id) {
                response = await API.put(`/checklist-categories.php?id=${id}`, categoryData);
            } else {
                response = await API.post('/checklist-categories.php', categoryData);
            }

            if (response.success) {
                Swal.fire('Success', response.message || 'Category saved successfully', 'success');
                
                const modal = bootstrap.Modal.getInstance(document.getElementById('categoryModal'));
                modal.hide();
                
                this.loadCategories();
            } else {
                Swal.fire('Error', response.message || 'Failed to save category', 'error');
            }
        } catch (error) {
            console.error('Error saving category:', error);
            Swal.fire('Error', 'Failed to save category', 'error');
        }
    }

    async deleteCategory(id) {
        const result = await Swal.fire({
            title: 'Are you sure?',
            text: 'This action cannot be undone!',
            icon: 'warning',
            showCancelButton: true,
            confirmButtonColor: '#d33',
            cancelButtonColor: '#3085d6',
            confirmButtonText: 'Yes, delete it!'
        });

        if (result.isConfirmed) {
            try {
                const response = await API.delete(`/checklist-categories.php?id=${id}`);
                
                if (response.success) {
                    Swal.fire('Success', response.message || 'Category deleted successfully', 'success');
                    this.loadCategories();
                } else {
                    Swal.fire('Error', response.message || 'Failed to delete category', 'error');
                }
            } catch (error) {
                console.error('Error deleting category:', error);
                Swal.fire('Error', 'Failed to delete category', 'error');
            }
        }
    }

    searchCategories(search) {
        this.currentPage = 1;
        this.loadCategories(search);
    }
}

// Add CSS for avatar circle
document.addEventListener('DOMContentLoaded', function() {
    // Add dynamic styles
    const style = document.createElement('style');
    style.textContent = `
        .avatar-circle {
            width: 40px;
            height: 40px;
            border-radius: 50%;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            display: flex;
            align-items: center;
            justify-content: center;
            font-weight: bold;
            font-size: 18px;
        }
        .visit-row:hover {
            background-color: #f8f9fa !important;
        }
    `;
    document.head.appendChild(style);
});

/**
 * Show Visit Detail Modal
 */
async function showVisitDetail(visitId, outletName, visitDate) {
    try {
        // Fetch visit responses
        const response = await API.get(`/visit-responses.php?visit_id=${visitId}`);
        
        if (!response.success) {
            Swal.fire('Error', 'Failed to load visit details', 'error');
            return;
        }
        
        const responses = response.data;
        
        // Normalize response values
        responses.forEach(resp => {
            // Normalize response value to lowercase and replace spaces with underscores
            const normalized = (resp.response_value || '').toLowerCase().replace(/ /g, '_');
            resp.response_value = normalized;
        });
        
        // Group responses by category
        const groupedResponses = {};
        responses.forEach(resp => {
            if (!groupedResponses[resp.category_name]) {
                groupedResponses[resp.category_name] = [];
            }
            groupedResponses[resp.category_name].push(resp);
        });
        
        // Build modal content
        let categoriesHTML = '';
        for (const [categoryName, items] of Object.entries(groupedResponses)) {
            categoriesHTML += `
                <div class="mb-4">
                    <h6 class="border-bottom pb-2">
                        <i class="fas fa-folder me-2"></i>${categoryName}
                    </h6>
                    <div class="list-group list-group-flush">
            `;
            
            items.forEach(item => {
                const responseIcon = {
                    'ok': '<i class="fas fa-check-circle text-success"></i>',
                    'not_ok': '<i class="fas fa-times-circle text-danger"></i>',
                    'na': '<i class="fas fa-minus-circle text-secondary"></i>'
                }[item.response_value] || '';
                
                const photoHTML = item.photo_url 
                    ? `<br><img src="${item.photo_url}" class="img-thumbnail mt-2" style="max-width: 200px; cursor: pointer;" onclick="showImageModal('${item.photo_url}')">`
                    : '';
                
                const notesHTML = item.notes 
                    ? `<br><small class="text-muted"><i class="fas fa-sticky-note me-1"></i>${item.notes}</small>`
                    : '';
                
                categoriesHTML += `
                    <div class="list-group-item">
                        <div class="d-flex justify-content-between align-items-start">
                            <div class="flex-grow-1">
                                <div class="fw-bold">${responseIcon} ${item.item_text}</div>
                                ${notesHTML}
                                ${photoHTML}
                            </div>
                        </div>
                    </div>
                `;
            });
            
            categoriesHTML += `
                    </div>
                </div>
            `;
        }
        
        // Show modal
        Swal.fire({
            title: `<i class="fas fa-clipboard-check me-2"></i>Visit Detail`,
            html: `
                <div class="text-start">
                    <div class="alert alert-info">
                        <strong><i class="fas fa-store me-2"></i>Outlet:</strong> ${outletName}<br>
                        <strong><i class="fas fa-calendar me-2"></i>Date:</strong> ${visitDate}
                    </div>
                    ${categoriesHTML}
                </div>
            `,
            width: '800px',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: {
                popup: 'text-start'
            }
        });
        
    } catch (error) {
        console.error('Error loading visit detail:', error);
        Swal.fire('Error', `Failed to load visit details: ${error.message}`, 'error');
    }
}

/**
 * Show Image in Modal
 */
function showImageModal(imageUrl) {
    Swal.fire({
        imageUrl: imageUrl,
        imageAlt: 'Visit Photo',
        showCloseButton: true,
        showConfirmButton: false,
        width: 'auto',
        customClass: {
            image: 'img-fluid'
        }
    });
}

/**
 * Show Finding Photos
 */
async function showFindingPhotos(findings, outletName, categoryName, question) {
    try {
        // Get photos for this finding
        const response = await API.get(`/finding-photos.php?outlet_name=${encodeURIComponent(outletName)}&question=${encodeURIComponent(question)}`);
        
        if (!response.success) {
            Swal.fire('Error', 'Failed to load photos', 'error');
            return;
        }
        
        // Backend API returns: {success: true, data: {data: [...], total: 5}}
        // So response.data is the object containing data array and total
        let photos = response.data?.data || response.data || [];
        
        // Ensure photos is an array
        if (!Array.isArray(photos)) {
            console.error('Photos is not an array:', photos);
            photos = [];
        }
        
        if (photos.length === 0) {
            Swal.fire('Info', 'No photos found for this finding', 'info');
            return;
        }
        
        // Build photo gallery
        let photosHTML = '<div class="row g-3">';
        photos.forEach(photo => {
            const photoDate = new Date(photo.visit_date).toLocaleDateString('id-ID', {
                year: 'numeric',
                month: 'short',
                day: 'numeric'
            });
            
            photosHTML += `
                <div class="col-md-6">
                    <div class="card">
                        <img src="${photo.photo_url}" class="card-img-top" style="cursor: pointer; height: 300px; object-fit: cover;" onclick="showImageModal('${photo.photo_url}')">
                        <div class="card-body">
                            <small class="text-muted">
                                <i class="fas fa-calendar me-1"></i>${photoDate}
                            </small>
                        </div>
                    </div>
                </div>
            `;
        });
        photosHTML += '</div>';
        
        // Show modal
        Swal.fire({
            title: `<i class="fas fa-camera me-2"></i>Finding Photos`,
            html: `
                <div class="text-start">
                    <div class="alert alert-warning">
                        <strong><i class="fas fa-store me-2"></i>Outlet:</strong> ${outletName}<br>
                        <strong><i class="fas fa-folder me-2"></i>Category:</strong> ${categoryName}<br>
                        <strong><i class="fas fa-exclamation-triangle me-2"></i>Issue:</strong> ${question}
                    </div>
                    <p class="text-muted mb-3">
                        <i class="fas fa-info-circle me-2"></i>Total ${photos.length} photo(s) found
                    </p>
                    ${photosHTML}
                </div>
            `,
            width: '900px',
            showCloseButton: true,
            showConfirmButton: false,
            customClass: {
                popup: 'text-start'
            }
        });
        
    } catch (error) {
        console.error('Error loading finding photos:', error);
        Swal.fire('Error', `Failed to load photos: ${error.message}`, 'error');
    }
}