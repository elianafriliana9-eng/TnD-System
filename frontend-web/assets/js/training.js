/**
 * Training Management JavaScript
 * TND System - Web Dashboard
 */

// Global variables
let currentScheduleId = null;
let currentChecklistId = null;
let sessionsChart = null;
let scoresChart = null;

// Show training page
async function showTraining() {
    setActiveMenuItem('Training');
    
    try {
        // Load training.html content
        const response = await fetch('training.html');
        const html = await response.text();
        document.getElementById('content-area').innerHTML = html;
        
        // Initialize training page after content is loaded
        setTimeout(() => {
            initializeTrainingPage();
        }, 100);
    } catch (error) {
        console.error('Error loading training page:', error);
        document.getElementById('content-area').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading training page. Please try again.
            </div>
        `;
    }
}

// Show training reports page
async function showTrainingReports() {
    setActiveMenuItem('Laporan Training');
    
    try {
        // Load training-reports.html content
        const response = await fetch('training-reports.html');
        const html = await response.text();
        document.getElementById('content-area').innerHTML = html;
        
        // Load the reports script dynamically
        const script = document.createElement('script');
        script.src = 'assets/js/training-reports.js';
        document.body.appendChild(script);
        
    } catch (error) {
        console.error('Error loading training reports page:', error);
        document.getElementById('content-area').innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle"></i>
                Error loading training reports page. Please try again.
            </div>
        `;
    }
}

// Initialize training page
function initializeTrainingPage() {
    // Set current month/year
    const now = new Date();
    const monthSelect = document.getElementById('reportMonth');
    const yearSelect = document.getElementById('reportYear');
    
    if (monthSelect && yearSelect) {
        monthSelect.value = now.getMonth() + 1;
        yearSelect.value = now.getFullYear();
    }
    
    // Load initial data
    loadStatistics();
    loadSchedules();
    loadChecklists();
    loadInstructors();
    loadMaterials();
    loadDropdowns();
}



// Load statistics
async function loadStatistics() {
    try {
        const response = await API.get('/training/stats.php');
        if (response.success) {
            const stats = response.data.summary;
            document.getElementById('totalSessions').textContent = stats.total_sessions || 0;
            document.getElementById('completedSessions').textContent = stats.completed_sessions || 0;
            document.getElementById('totalParticipants').textContent = stats.total_participants || 0;
            document.getElementById('avgScore').textContent = (stats.overall_average_score || 0).toFixed(1);
        }
    } catch (error) {
        console.error('Error loading statistics:', error);
    }
}

// Load schedules
async function loadSchedules() {
    try {
        const response = await API.get('/training/sessions-list.php');
        const tbody = document.getElementById('scheduleTableBody');
        
        if (response.success && response.data.length > 0) {
            tbody.innerHTML = response.data.map(session => `
                <tr>
                    <td>${session.id}</td>
                    <td>${formatDate(session.session_date)}</td>
                    <td>${session.outlet?.name || '-'}</td>
                    <td>${session.trainer?.name || '-'}</td>
                    <td>${session.checklist?.name || '-'}</td>
                    <td>${getStatusBadge(session.status)}</td>
                    <td>${session.counts?.participants || 0}</td>
                    <td>${session.average_score ? session.average_score.toFixed(1) : '-'}</td>
                    <td>
                        <button class="btn btn-sm btn-info" onclick="viewSessionDetail(${session.id})" title="Detail">
                            <i class="fas fa-eye"></i>
                        </button>
                        <button class="btn btn-sm btn-warning" onclick="editSchedule(${session.id})" title="Edit">
                            <i class="fas fa-edit"></i>
                        </button>
                        <button class="btn btn-sm btn-danger" onclick="deleteSchedule(${session.id})" title="Hapus">
                            <i class="fas fa-trash"></i>
                        </button>
                    </td>
                </tr>
            `).join('');
        } else {
            tbody.innerHTML = '<tr><td colspan="9" class="text-center">Belum ada jadwal training</td></tr>';
        }
    } catch (error) {
        console.error('Error loading schedules:', error);
        document.getElementById('scheduleTableBody').innerHTML = 
            '<tr><td colspan="9" class="text-center text-danger">Error loading data</td></tr>';
    }
}

// Load checklists
async function loadChecklists() {
    try {
        const response = await API.get('/training/checklists.php');
        const container = document.getElementById('checklistsContainer');
        
        if (response.success && response.data.length > 0) {
            container.innerHTML = response.data.map(checklist => `
                <div class="card mb-3">
                    <div class="card-header d-flex justify-content-between align-items-center">
                        <h6 class="mb-0">${checklist.name}</h6>
                        <div>
                            <span class="badge bg-${checklist.is_active ? 'success' : 'secondary'}">
                                ${checklist.is_active ? 'Active' : 'Inactive'}
                            </span>
                            <button class="btn btn-sm btn-info ms-2" onclick="viewChecklistDetail(${checklist.id})">
                                <i class="fas fa-eye"></i> Detail
                            </button>
                            <button class="btn btn-sm btn-warning" onclick="editChecklist(${checklist.id})">
                                <i class="fas fa-edit"></i>
                            </button>
                            <button class="btn btn-sm btn-danger" onclick="deleteChecklist(${checklist.id})">
                                <i class="fas fa-trash"></i>
                            </button>
                        </div>
                    </div>
                    <div class="card-body">
                        <p class="text-muted">${checklist.description || 'No description'}</p>
                        <div class="row">
                            <div class="col-md-4">
                                <small class="text-muted">Categories: ${checklist.categories_count || 0}</small>
                            </div>
                            <div class="col-md-4">
                                <small class="text-muted">Points: ${checklist.points_count || 0}</small>
                            </div>
                            <div class="col-md-4">
                                <small class="text-muted">Created: ${formatDate(checklist.created_at)}</small>
                            </div>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            container.innerHTML = '<p class="text-muted">Belum ada checklist. Tambahkan checklist baru untuk memulai.</p>';
        }
    } catch (error) {
        console.error('Error loading checklists:', error);
    }
}

// Load instructors
async function loadInstructors() {
    try {
        const response = await API.get('/users.php?role=trainer');
        const tbody = document.getElementById('instructorsTableBody');
        
        if (response.success && response.data) {
            const instructors = response.data.data || response.data;
            if (instructors.length > 0) {
                tbody.innerHTML = instructors.map(instructor => {
                    // Map is_active to status
                    const status = instructor.is_active == 1 ? 'active' : 'inactive';
                    return `
                        <tr>
                            <td>${instructor.id}</td>
                            <td>${instructor.name}</td>
                            <td>${instructor.email}</td>
                            <td>${instructor.phone || '-'}</td>
                            <td>${instructor.specialization || '-'}</td>
                            <td>
                                <span class="badge bg-${status === 'active' ? 'success' : 'secondary'}">
                                    ${status === 'active' ? 'Active' : 'Inactive'}
                                </span>
                            </td>
                            <td>
                                <button class="btn btn-sm btn-info" onclick="editInstructor(${instructor.id})" title="Edit">
                                    <i class="fas fa-edit"></i>
                                </button>
                                <button class="btn btn-sm btn-danger" onclick="deleteInstructor(${instructor.id})" title="Hapus">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </td>
                        </tr>
                    `;
                }).join('');
            } else {
                tbody.innerHTML = '<tr><td colspan="7" class="text-center">Belum ada data instruktur</td></tr>';
            }
        } else {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center">Belum ada data instruktur</td></tr>';
        }
    } catch (error) {
        console.error('Error loading instructors:', error);
        document.getElementById('instructorsTableBody').innerHTML = 
            '<tr><td colspan="7" class="text-center text-danger">Error loading data</td></tr>';
    }
}

// Load materials
async function loadMaterials() {
    try {
        const response = await API.get('/training/materials.php');
        const container = document.getElementById('materialsContainer');
        
        if (response.success && response.data && response.data.length > 0) {
            container.innerHTML = response.data.map(material => `
                <div class="col-md-4 mb-4">
                    <div class="card h-100">
                        ${material.thumbnail_path ? 
                            `<img src="${material.thumbnail_path}" class="card-img-top" alt="${material.title}" style="height: 200px; object-fit: cover;">` :
                            `<div class="card-img-top bg-secondary d-flex align-items-center justify-content-center" style="height: 200px;">
                                <i class="fas fa-${material.file_type === 'pdf' ? 'file-pdf' : 'file-powerpoint'} fa-4x text-white"></i>
                            </div>`
                        }
                        <div class="card-body">
                            <h6 class="card-title">${material.title}</h6>
                            <p class="card-text text-muted small">${material.description || 'No description'}</p>
                            <span class="badge bg-info">${material.category}</span>
                            <span class="badge bg-secondary">${material.file_type.toUpperCase()}</span>
                        </div>
                        <div class="card-footer bg-transparent">
                            <small class="text-muted">Uploaded: ${formatDate(material.uploaded_at)}</small>
                            <div class="mt-2">
                                <button class="btn btn-sm btn-primary" onclick="viewMaterial(${material.id}, '${material.file_path}', '${material.title}')">
                                    <i class="fas fa-eye"></i> Preview
                                </button>
                                <button class="btn btn-sm btn-success" onclick="downloadMaterial('${material.file_path}', '${material.title}')">
                                    <i class="fas fa-download"></i>
                                </button>
                                <button class="btn btn-sm btn-danger" onclick="deleteMaterial(${material.id})">
                                    <i class="fas fa-trash"></i>
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            `).join('');
        } else {
            container.innerHTML = '<div class="col-12 text-center"><p class="text-muted">Belum ada materi training. Upload materi baru untuk memulai.</p></div>';
        }
    } catch (error) {
        console.error('Error loading materials:', error);
        document.getElementById('materialsContainer').innerHTML = 
            '<div class="col-12 text-center"><p class="text-danger">Error loading materials</p></div>';
    }
}

// Load dropdowns for forms
async function loadDropdowns() {
    try {
        // Load outlets
        const outletsResponse = await API.get('/outlets.php?simple=true');
        const outletSelect = document.getElementById('schedule_outlet_id');
        if (outletsResponse.success && outletsResponse.data) {
            const outlets = outletsResponse.data.data || outletsResponse.data;
            outletSelect.innerHTML = '<option value="">Pilih Outlet</option>' +
                outlets.map(outlet => 
                    `<option value="${outlet.id}">${outlet.name}</option>`
                ).join('');
        }
        
        // Load trainers
        const trainersResponse = await API.get('/users.php?role=trainer');
        const trainerSelect = document.getElementById('schedule_trainer_id');
        if (trainersResponse.success && trainersResponse.data) {
            const trainers = trainersResponse.data.data || trainersResponse.data;
            trainerSelect.innerHTML = '<option value="">Pilih Trainer</option>' +
                trainers.map(trainer => 
                    `<option value="${trainer.id}">${trainer.name}</option>`
                ).join('');
        }
        
        // Load checklists for dropdown
        const checklistsResponse = await API.get('/training/checklists.php');
        const checklistSelect = document.getElementById('schedule_checklist_id');
        if (checklistsResponse.success && checklistsResponse.data) {
            checklistSelect.innerHTML = '<option value="">Pilih Checklist</option>' +
                checklistsResponse.data.map(checklist => 
                    `<option value="${checklist.id}">${checklist.name}</option>`
                ).join('');
        }
    } catch (error) {
        console.error('Error loading dropdowns:', error);
    }
}

// Show schedule modal
function showScheduleModal(scheduleId = null) {
    currentScheduleId = scheduleId;
    const modal = new bootstrap.Modal(document.getElementById('scheduleModal'));
    
    if (scheduleId) {
        // Load existing schedule data
        // TODO: Implement edit mode
    } else {
        // Clear form for new schedule
        document.getElementById('scheduleForm').reset();
    }
    
    modal.show();
}

// Save schedule
async function saveSchedule() {
    try {
        const data = {
            outlet_id: document.getElementById('schedule_outlet_id').value,
            trainer_id: document.getElementById('schedule_trainer_id').value,
            checklist_id: document.getElementById('schedule_checklist_id').value,
            session_date: document.getElementById('schedule_date').value,
            start_time: document.getElementById('schedule_start_time').value || null,
            end_time: document.getElementById('schedule_end_time').value || null,
            notes: document.getElementById('schedule_notes').value || null
        };
        
        // Validation
        if (!data.outlet_id || !data.trainer_id || !data.checklist_id || !data.session_date) {
            alert('Mohon lengkapi semua field yang wajib diisi');
            return;
        }
        
        const response = await API.post('/training/session-start.php', data);
        
        if (response.success) {
            alert('Jadwal training berhasil disimpan');
            bootstrap.Modal.getInstance(document.getElementById('scheduleModal')).hide();
            await loadSchedules();
            await loadStatistics();
        } else {
            alert('Error: ' + (response.message || 'Gagal menyimpan jadwal'));
        }
    } catch (error) {
        console.error('Error saving schedule:', error);
        alert('Error: ' + error.message);
    }
}

// Delete schedule
async function deleteSchedule(id) {
    if (!confirm('Apakah Anda yakin ingin menghapus jadwal training ini?')) {
        return;
    }
    
    try {
        const response = await API.delete(`/training/session-delete.php?id=${id}`);
        
        if (response.success) {
            alert(response.message || 'Jadwal training berhasil dihapus');
            await loadSchedules();
        } else {
            alert('Error: ' + (response.message || 'Gagal menghapus jadwal'));
        }
    } catch (error) {
        console.error('Error deleting schedule:', error);
        alert('Error: ' + error.message);
    }
}

// Show checklist modal
function showChecklistModal(checklistId = null) {
    currentChecklistId = checklistId;
    const modal = new bootstrap.Modal(document.getElementById('checklistModal'));
    
    if (checklistId) {
        // Edit mode will be handled by editChecklist function
        editChecklist(checklistId);
        return;
    } else {
        // Clear form for new checklist
        document.getElementById('checklistForm').reset();
        document.getElementById('categoriesContainer').innerHTML = '';
        categoryCounter = 0;
        pointCounter = 0;
        
        // Reset modal title
        document.querySelector('#checklistModal .modal-title').textContent = 'Tambah Form Checklist';
        
        addCategory(); // Add first category
    }
    
    modal.show();
}

// Add category to checklist form
let categoryCounter = 0;
function addCategory() {
    categoryCounter++;
    const container = document.getElementById('categoriesContainer');
    const categoryHtml = `
        <div class="card mb-3" id="category_${categoryCounter}">
            <div class="card-header d-flex justify-content-between align-items-center">
                <input type="text" class="form-control form-control-sm w-75" 
                       placeholder="Nama Kategori" 
                       id="category_name_${categoryCounter}" required>
                <button type="button" class="btn btn-sm btn-danger" onclick="removeCategory(${categoryCounter})">
                    <i class="fas fa-times"></i>
                </button>
            </div>
            <div class="card-body">
                <div id="points_container_${categoryCounter}">
                    <!-- Points will be added here -->
                </div>
                <button type="button" class="btn btn-sm btn-secondary mt-2" 
                        onclick="addPoint(${categoryCounter})">
                    <i class="fas fa-plus"></i> Tambah Poin
                </button>
            </div>
        </div>
    `;
    container.insertAdjacentHTML('beforeend', categoryHtml);
    addPoint(categoryCounter); // Add first point
}

// Remove category
function removeCategory(categoryId) {
    document.getElementById(`category_${categoryId}`).remove();
}

// Add point to category
let pointCounter = 0;
function addPoint(categoryId) {
    pointCounter++;
    const container = document.getElementById(`points_container_${categoryId}`);
    const pointHtml = `
        <div class="input-group mb-2" id="point_${pointCounter}">
            <input type="text" class="form-control" 
                   placeholder="Pertanyaan/Poin evaluasi" 
                   id="point_text_${pointCounter}" required>
            <button class="btn btn-outline-danger" type="button" 
                    onclick="removePoint(${pointCounter})">
                <i class="fas fa-times"></i>
            </button>
        </div>
    `;
    container.insertAdjacentHTML('beforeend', pointHtml);
}

// Remove point
function removePoint(pointId) {
    document.getElementById(`point_${pointId}`).remove();
}

// Save checklist
async function saveChecklist() {
    try {
        // Validate checklist name
        const name = document.getElementById('checklist_name').value.trim();
        if (!name) {
            alert('Nama checklist harus diisi');
            return;
        }
        
        const description = document.getElementById('checklist_description').value.trim();
        
        // Collect categories and points
        const categories = [];
        const categoryElements = document.querySelectorAll('[id^="category_"]');
        
        if (categoryElements.length === 0) {
            alert('Minimal harus ada 1 kategori');
            return;
        }
        
        for (const categoryElement of categoryElements) {
            const categoryId = categoryElement.id.split('_')[1];
            const categoryNameInput = document.getElementById(`category_name_${categoryId}`);
            
            if (!categoryNameInput) continue;
            
            const categoryName = categoryNameInput.value.trim();
            if (!categoryName) {
                alert('Semua kategori harus memiliki nama');
                return;
            }
            
            // Collect points for this category
            const points = [];
            const pointElements = document.querySelectorAll(`#points_container_${categoryId} [id^="point_text_"]`);
            
            if (pointElements.length === 0) {
                alert(`Kategori "${categoryName}" harus memiliki minimal 1 poin evaluasi`);
                return;
            }
            
            for (const pointElement of pointElements) {
                const pointText = pointElement.value.trim();
                if (!pointText) {
                    alert('Semua poin evaluasi harus diisi');
                    return;
                }
                points.push(pointText);
            }
            
            categories.push({
                name: categoryName,
                points: points
            });
        }
        
        // Prepare data
        const data = {
            id: currentChecklistId,
            name: name,
            description: description,
            categories: categories
        };
        
        // Send to API
        const response = await API.post('/training/checklist-save.php', data);
        
        if (response.success) {
            alert(response.message || 'Checklist berhasil disimpan');
            
            // Close modal
            const modal = bootstrap.Modal.getInstance(document.getElementById('checklistModal'));
            modal.hide();
            
            // Reload checklists
            await loadChecklists();
        } else {
            alert(response.message || 'Gagal menyimpan checklist');
        }
        
    } catch (error) {
        console.error('Error saving checklist:', error);
        alert('Error: ' + (error.message || 'Gagal menyimpan checklist'));
    }
}

// View checklist detail
async function viewChecklistDetail(checklistId) {
    try {
        const response = await API.get(`/training/checklist-detail.php?id=${checklistId}`);
        
        if (response.success && response.data) {
            const checklist = response.data;
            let detailHtml = `
                <div class="modal fade" id="checklistDetailModal" tabindex="-1">
                    <div class="modal-dialog modal-lg">
                        <div class="modal-content">
                            <div class="modal-header">
                                <h5 class="modal-title">${checklist.name}</h5>
                                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                            </div>
                            <div class="modal-body">
                                <p class="text-muted">${checklist.description || 'No description'}</p>
                                <hr>
            `;
            
            if (checklist.categories && checklist.categories.length > 0) {
                checklist.categories.forEach((category, catIndex) => {
                    detailHtml += `
                        <div class="mb-4">
                            <h6 class="text-primary">${catIndex + 1}. ${category.category_name}</h6>
                            <ol>
                    `;
                    
                    if (category.points && category.points.length > 0) {
                        category.points.forEach(point => {
                            detailHtml += `<li>${point.point_text}</li>`;
                        });
                    }
                    
                    detailHtml += `
                            </ol>
                        </div>
                    `;
                });
            } else {
                detailHtml += '<p class="text-muted">Belum ada kategori dan poin evaluasi</p>';
            }
            
            detailHtml += `
                            </div>
                            <div class="modal-footer">
                                <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Tutup</button>
                                <button type="button" class="btn btn-warning" onclick="editChecklist(${checklistId})">
                                    <i class="fas fa-edit"></i> Edit
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            `;
            
            // Remove existing modal if any
            const existingModal = document.getElementById('checklistDetailModal');
            if (existingModal) {
                existingModal.remove();
            }
            
            // Add modal to body and show
            document.body.insertAdjacentHTML('beforeend', detailHtml);
            const modal = new bootstrap.Modal(document.getElementById('checklistDetailModal'));
            modal.show();
            
            // Remove modal from DOM when hidden
            document.getElementById('checklistDetailModal').addEventListener('hidden.bs.modal', function() {
                this.remove();
            });
        }
    } catch (error) {
        console.error('Error viewing checklist detail:', error);
        alert('Error: Gagal memuat detail checklist');
    }
}

// Edit checklist
async function editChecklist(checklistId) {
    try {
        // Close detail modal if open
        const detailModal = document.getElementById('checklistDetailModal');
        if (detailModal) {
            bootstrap.Modal.getInstance(detailModal)?.hide();
        }
        
        const response = await API.get(`/training/checklist-detail.php?id=${checklistId}`);
        
        if (response.success && response.data) {
            const checklist = response.data;
            
            // Set current checklist ID for update
            currentChecklistId = checklistId;
            
            // Fill form
            document.getElementById('checklist_name').value = checklist.name;
            document.getElementById('checklist_description').value = checklist.description || '';
            
            // Clear categories container
            document.getElementById('categoriesContainer').innerHTML = '';
            categoryCounter = 0;
            pointCounter = 0;
            
            // Add categories and points
            if (checklist.categories && checklist.categories.length > 0) {
                checklist.categories.forEach(category => {
                    categoryCounter++;
                    const catId = categoryCounter;
                    
                    const categoryHtml = `
                        <div class="card mb-3" id="category_${catId}">
                            <div class="card-header d-flex justify-content-between align-items-center">
                                <input type="text" class="form-control form-control-sm w-75" 
                                       placeholder="Nama Kategori" 
                                       id="category_name_${catId}" 
                                       value="${category.category_name}" required>
                                <button type="button" class="btn btn-sm btn-danger" onclick="removeCategory(${catId})">
                                    <i class="fas fa-times"></i>
                                </button>
                            </div>
                            <div class="card-body">
                                <div id="points_container_${catId}">
                                    <!-- Points will be added here -->
                                </div>
                                <button type="button" class="btn btn-sm btn-secondary mt-2" 
                                        onclick="addPoint(${catId})">
                                    <i class="fas fa-plus"></i> Tambah Poin
                                </button>
                            </div>
                        </div>
                    `;
                    document.getElementById('categoriesContainer').insertAdjacentHTML('beforeend', categoryHtml);
                    
                    // Add points
                    if (category.points && category.points.length > 0) {
                        category.points.forEach(point => {
                            pointCounter++;
                            const pointId = pointCounter;
                            
                            const pointHtml = `
                                <div class="input-group mb-2" id="point_${pointId}">
                                    <input type="text" class="form-control" 
                                           placeholder="Pertanyaan/Poin evaluasi" 
                                           id="point_text_${pointId}" 
                                           value="${point.point_text}" required>
                                    <button class="btn btn-outline-danger" type="button" 
                                            onclick="removePoint(${pointId})">
                                        <i class="fas fa-times"></i>
                                    </button>
                                </div>
                            `;
                            document.getElementById(`points_container_${catId}`).insertAdjacentHTML('beforeend', pointHtml);
                        });
                    }
                });
            }
            
            // Update modal title
            document.querySelector('#checklistModal .modal-title').textContent = 'Edit Form Checklist';
            
            // Show modal
            const modal = new bootstrap.Modal(document.getElementById('checklistModal'));
            modal.show();
        }
    } catch (error) {
        console.error('Error loading checklist for edit:', error);
        alert('Error: Gagal memuat data checklist');
    }
}

// Delete checklist
async function deleteChecklist(checklistId) {
    if (!confirm('Apakah Anda yakin ingin menghapus checklist ini?')) {
        return;
    }
    
    try {
        const response = await API.delete(`/training/checklist-delete.php?id=${checklistId}`);
        
        if (response.success) {
            alert(response.message || 'Checklist berhasil dihapus');
            await loadChecklists();
        } else {
            alert(response.message || 'Gagal menghapus checklist');
        }
    } catch (error) {
        console.error('Error deleting checklist:', error);
        alert('Error: ' + (error.message || 'Gagal menghapus checklist'));
    }
}

// Generate monthly report
async function generateReport() {
    const month = document.getElementById('reportMonth').value;
    const year = document.getElementById('reportYear').value;
    
    const startDate = `${year}-${month.padStart(2, '0')}-01`;
    const endDate = new Date(year, month, 0);
    const endDateStr = `${year}-${month.padStart(2, '0')}-${endDate.getDate()}`;
    
    try {
        const response = await API.get(`/training/stats.php?date_from=${startDate}&date_to=${endDateStr}`);
        
        if (response.success) {
            displayReport(response.data, month, year);
            renderCharts(response.data);
        }
    } catch (error) {
        console.error('Error generating report:', error);
    }
}

// Display report
function displayReport(data, month, year) {
    const monthNames = ['Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                       'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'];
    
    const html = `
        <div class="report-header mb-4">
            <h4>Laporan Training Bulan ${monthNames[month - 1]} ${year}</h4>
            <hr>
        </div>
        
        <div class="row mb-4">
            <div class="col-md-3">
                <div class="card bg-primary text-white">
                    <div class="card-body">
                        <h6>Total Sessions</h6>
                        <h3>${data.summary.total_sessions}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-success text-white">
                    <div class="card-body">
                        <h6>Completed</h6>
                        <h3>${data.summary.completed_sessions}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-info text-white">
                    <div class="card-body">
                        <h6>Participants</h6>
                        <h3>${data.summary.total_participants}</h3>
                    </div>
                </div>
            </div>
            <div class="col-md-3">
                <div class="card bg-warning text-white">
                    <div class="card-body">
                        <h6>Avg Score</h6>
                        <h3>${data.summary.overall_average_score.toFixed(1)}</h3>
                    </div>
                </div>
            </div>
        </div>
        
        <div class="table-responsive">
            <table class="table table-bordered">
                <thead class="table-light">
                    <tr>
                        <th>Tanggal</th>
                        <th>Outlet</th>
                        <th>Trainer</th>
                        <th>Participants</th>
                        <th>Score</th>
                        <th>Status</th>
                    </tr>
                </thead>
                <tbody>
                    ${data.recent_sessions.map(session => `
                        <tr>
                            <td>${formatDate(session.session_date)}</td>
                            <td>${session.outlet_name}</td>
                            <td>${session.trainer_name}</td>
                            <td>${session.participants_count}</td>
                            <td>${session.average_score.toFixed(1)}</td>
                            <td><span class="badge bg-success">Completed</span></td>
                        </tr>
                    `).join('')}
                </tbody>
            </table>
        </div>
    `;
    
    document.getElementById('reportContent').innerHTML = html;
}

// Render charts
function renderCharts(data) {
    // Sessions chart
    const sessionsCtx = document.getElementById('sessionsChart').getContext('2d');
    if (sessionsChart) sessionsChart.destroy();
    
    sessionsChart = new Chart(sessionsCtx, {
        type: 'bar',
        data: {
            labels: data.daily_trend.map(d => formatDate(d.date)),
            datasets: [{
                label: 'Sessions',
                data: data.daily_trend.map(d => d.sessions_count),
                backgroundColor: 'rgba(54, 162, 235, 0.5)'
            }]
        },
        options: {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: 'Training Sessions per Day'
                }
            }
        }
    });
    
    // Scores chart
    const scoresCtx = document.getElementById('scoresChart').getContext('2d');
    if (scoresChart) scoresChart.destroy();
    
    scoresChart = new Chart(scoresCtx, {
        type: 'line',
        data: {
            labels: data.daily_trend.map(d => formatDate(d.date)),
            datasets: [{
                label: 'Average Score',
                data: data.daily_trend.map(d => d.avg_score),
                borderColor: 'rgba(75, 192, 192, 1)',
                tension: 0.1
            }]
        },
        options: {
            responsive: true,
            plugins: {
                title: {
                    display: true,
                    text: 'Average Score Trend'
                }
            },
            scales: {
                y: {
                    beginAtZero: true,
                    max: 5
                }
            }
        }
    });
}

// Export report to PDF
function exportReportPDF() {
    alert('Export to PDF functionality will be implemented');
    // TODO: Implement PDF export using jsPDF or server-side generation
}

// View session detail
// View session detail
async function viewSessionDetail(id) {
    try {
        const response = await API.get(`/training/session-detail.php?id=${id}`);
        
        if (response.success) {
            showSessionDetailModal(response.data);
        } else {
            alert('Error loading session detail: ' + response.message);
        }
    } catch (error) {
        console.error('Error loading session detail:', error);
        alert('Failed to load session detail');
    }
}

// Show session detail modal
function showSessionDetailModal(session) {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.id = 'sessionDetailModal';
    modal.setAttribute('tabindex', '-1');
    
    // Get rating summary
    const ratingSummary = session.rating_summary || {
        total_points: 0,
        baik: { count: 0, percentage: 0 },
        cukup: { count: 0, percentage: 0 },
        kurang: { count: 0, percentage: 0 }
    };
    
    // Build evaluation by category
    const categoriesHtml = session.evaluation_summary && session.evaluation_summary.length > 0
        ? session.evaluation_summary.map(cat => `
            <div class="card mb-3">
                <div class="card-header bg-light">
                    <h6 class="mb-0"><i class="fas fa-folder"></i> ${cat.category_name}</h6>
                </div>
                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table table-sm table-hover">
                            <thead class="table-light">
                                <tr>
                                    <th width="50%">Checklist Point</th>
                                    <th width="20%">Rating</th>
                                    <th width="30%">Notes</th>
                                </tr>
                            </thead>
                            <tbody>
                                ${cat.points.map(point => {
                                    let badgeClass = 'secondary';
                                    let badgeText = 'Not Evaluated';
                                    
                                    if (point.rating === 'baik') {
                                        badgeClass = 'success';
                                        badgeText = 'Baik';
                                    } else if (point.rating === 'cukup') {
                                        badgeClass = 'warning';
                                        badgeText = 'Cukup';
                                    } else if (point.rating === 'kurang') {
                                        badgeClass = 'danger';
                                        badgeText = 'Kurang';
                                    }
                                    
                                    return `
                                        <tr>
                                            <td>${point.point_text}</td>
                                            <td>
                                                <span class="badge bg-${badgeClass}">${badgeText}</span>
                                            </td>
                                            <td><small class="text-muted">${point.notes || '-'}</small></td>
                                        </tr>
                                    `;
                                }).join('')}
                            </tbody>
                        </table>
                    </div>
                </div>
            </div>
        `).join('')
        : '<p class="text-muted">Belum ada evaluasi</p>';
    
    // Build training topics
    const topicsHtml = session.topics && session.topics.length > 0
        ? `
            <ul class="list-group">
                ${session.topics.map((topic, index) => `
                    <li class="list-group-item">
                        <i class="fas fa-book text-primary"></i> ${index + 1}. ${topic}
                    </li>
                `).join('')}
            </ul>
        `
        : '<p class="text-muted">Belum ada materi training</p>';
    
    // Build signatures
    const signaturesHtml = session.signatures ? `
        <div class="row">
            <div class="col-md-4 mb-3">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-user fa-2x text-primary mb-2"></i>
                        <h6>Staff / PIC Outlet</h6>
                        <p class="mb-0"><strong>${session.signatures.staff?.name || '-'}</strong></p>
                        <small class="text-muted">${session.signatures.staff?.position || '-'}</small>
                    </div>
                </div>
            </div>
            <div class="col-md-4 mb-3">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-user-tie fa-2x text-warning mb-2"></i>
                        <h6>Leader / Supervisor</h6>
                        <p class="mb-0"><strong>${session.signatures.leader?.name || '-'}</strong></p>
                        <small class="text-muted">${session.signatures.leader?.position || '-'}</small>
                    </div>
                </div>
            </div>
            <div class="col-md-4 mb-3">
                <div class="card h-100">
                    <div class="card-body text-center">
                        <i class="fas fa-chalkboard-teacher fa-2x text-success mb-2"></i>
                        <h6>Trainer</h6>
                        <p class="mb-0"><strong>${session.signatures.trainer?.name || '-'}</strong></p>
                        <small class="text-muted">${session.signatures.trainer?.position || '-'}</small>
                    </div>
                </div>
            </div>
        </div>
    ` : '<p class="text-muted">Belum ada tanda tangan</p>';
    
    const photosHtml = session.photos && session.photos.length > 0
        ? session.photos.map(photo => `
            <div class="col-md-3 mb-3">
                <img src="${photo.photo_url}" class="img-fluid rounded shadow-sm" alt="Training Photo" 
                     onclick="showImageModal('${photo.photo_url}')"
                     style="cursor: pointer; object-fit: cover; height: 150px; width: 100%;">
                <small class="text-muted d-block mt-1">${photo.caption || ''}</small>
            </div>
        `).join('')
        : '<p class="text-muted">Belum ada foto</p>';
    
    modal.innerHTML = `
        <div class="modal-dialog modal-xl">
            <div class="modal-content">
                <div class="modal-header bg-primary text-white">
                    <h5 class="modal-title">
                        <i class="fas fa-graduation-cap"></i> Detail Training Session #${session.id}
                    </h5>
                    <button type="button" class="btn-close btn-close-white" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body">
                    <!-- Session Info -->
                    <div class="row mb-4">
                        <div class="col-md-6">
                            <table class="table table-bordered">
                                <tr>
                                    <th width="40%"><i class="fas fa-store"></i> Outlet</th>
                                    <td>${session.outlet?.name || '-'}</td>
                                </tr>
                                <tr>
                                    <th><i class="fas fa-clipboard-list"></i> Checklist</th>
                                    <td>${session.checklist?.name || '-'}</td>
                                </tr>
                                <tr>
                                    <th><i class="fas fa-chalkboard-teacher"></i> Trainer</th>
                                    <td>${session.trainer?.name || '-'}</td>
                                </tr>
                            </table>
                        </div>
                        <div class="col-md-6">
                            <table class="table table-bordered">
                                <tr>
                                    <th width="40%"><i class="fas fa-calendar"></i> Tanggal</th>
                                    <td>${formatDate(session.session_date)}</td>
                                </tr>
                                <tr>
                                    <th><i class="fas fa-clock"></i> Waktu</th>
                                    <td>${session.start_time} - ${session.end_time || 'Ongoing'}</td>
                                </tr>
                                <tr>
                                    <th><i class="fas fa-info-circle"></i> Status</th>
                                    <td>${getStatusBadge(session.status)}</td>
                                </tr>
                            </table>
                        </div>
                    </div>
                    
                    <!-- Rating Summary -->
                    ${session.status === 'completed' ? `
                    <div class="card mb-4 bg-light">
                        <div class="card-body">
                            <h6 class="card-title"><i class="fas fa-chart-pie"></i> Rating Summary</h6>
                            <div class="row text-center">
                                <div class="col-md-3">
                                    <div class="p-3 bg-white rounded">
                                        <h3 class="mb-0">${ratingSummary.total_points}</h3>
                                        <small class="text-muted">Total Points</small>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-white rounded">
                                        <h3 class="mb-0 text-success">${ratingSummary.baik.count}</h3>
                                        <small class="text-muted">Baik (${ratingSummary.baik.percentage}%)</small>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-white rounded">
                                        <h3 class="mb-0 text-warning">${ratingSummary.cukup.count}</h3>
                                        <small class="text-muted">Cukup (${ratingSummary.cukup.percentage}%)</small>
                                    </div>
                                </div>
                                <div class="col-md-3">
                                    <div class="p-3 bg-white rounded">
                                        <h3 class="mb-0 text-danger">${ratingSummary.kurang.count}</h3>
                                        <small class="text-muted">Kurang (${ratingSummary.kurang.percentage}%)</small>
                                    </div>
                                </div>
                            </div>
                            <div class="progress mt-3" style="height: 25px;">
                                <div class="progress-bar bg-success" style="width: ${ratingSummary.baik.percentage}%">
                                    ${ratingSummary.baik.percentage > 10 ? ratingSummary.baik.percentage + '%' : ''}
                                </div>
                                <div class="progress-bar bg-warning" style="width: ${ratingSummary.cukup.percentage}%">
                                    ${ratingSummary.cukup.percentage > 10 ? ratingSummary.cukup.percentage + '%' : ''}
                                </div>
                                <div class="progress-bar bg-danger" style="width: ${ratingSummary.kurang.percentage}%">
                                    ${ratingSummary.kurang.percentage > 10 ? ratingSummary.kurang.percentage + '%' : ''}
                                </div>
                            </div>
                        </div>
                    </div>
                    ` : ''}
                    
                    ${session.notes ? `
                        <div class="alert alert-info mb-4">
                            <strong><i class="fas fa-sticky-note"></i> Notes:</strong> ${session.notes}
                        </div>
                    ` : ''}
                    
                    <!-- Tabs -->
                    <ul class="nav nav-tabs mb-3" role="tablist">
                        <li class="nav-item">
                            <a class="nav-link active" data-bs-toggle="tab" href="#evaluation-tab">
                                <i class="fas fa-clipboard-check"></i> Evaluasi
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" data-bs-toggle="tab" href="#topics-tab">
                                <i class="fas fa-book"></i> Materi Training
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" data-bs-toggle="tab" href="#signatures-tab">
                                <i class="fas fa-signature"></i> Tanda Tangan
                            </a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" data-bs-toggle="tab" href="#photos-tab">
                                <i class="fas fa-camera"></i> Foto (${session.counts?.photos || 0})
                            </a>
                        </li>
                    </ul>
                    
                    <div class="tab-content">
                        <!-- Evaluation Tab -->
                        <div class="tab-pane fade show active" id="evaluation-tab">
                            ${categoriesHtml}
                        </div>
                        
                        <!-- Training Topics Tab -->
                        <div class="tab-pane fade" id="topics-tab">
                            <h6 class="mb-3"><i class="fas fa-book"></i> Materi yang Diberikan:</h6>
                            ${topicsHtml}
                        </div>
                        
                        <!-- Signatures Tab -->
                        <div class="tab-pane fade" id="signatures-tab">
                            <h6 class="mb-3"><i class="fas fa-signature"></i> Tanda Tangan:</h6>
                            ${signaturesHtml}
                        </div>
                        
                        <!-- Photos Tab -->
                        <div class="tab-pane fade" id="photos-tab">
                            <div class="row">
                                ${photosHtml}
                            </div>
                        </div>
                    </div>
                </div>
                <div class="modal-footer">
                    <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">
                        <i class="fas fa-times"></i> Close
                    </button>
                    ${session.status === 'completed' ? `
                        <button type="button" class="btn btn-primary" onclick="exportSessionPDF(${session.id})">
                            <i class="fas fa-file-pdf"></i> Export PDF
                        </button>
                    ` : ''}
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
    
    // Remove modal from DOM after hide
    modal.addEventListener('hidden.bs.modal', function () {
        modal.remove();
    });
}

// Instructor Management Functions
function showAddInstructorModal() {
    document.getElementById('instructorForm').reset();
    document.getElementById('instructor_id').value = '';
    document.getElementById('instructor_password').required = true;
    const modal = new bootstrap.Modal(document.getElementById('instructorModal'));
    modal.show();
}

async function editInstructor(id) {
    try {
        const response = await API.get(`/users.php?id=${id}`);
        if (response.success && response.data) {
            const instructor = response.data;
            document.getElementById('instructor_id').value = instructor.id;
            document.getElementById('instructor_name').value = instructor.name;
            document.getElementById('instructor_email').value = instructor.email;
            document.getElementById('instructor_phone').value = instructor.phone || '';
            document.getElementById('instructor_specialization').value = instructor.specialization || '';
            // Map is_active to status
            document.getElementById('instructor_status').value = instructor.is_active == 1 ? 'active' : 'inactive';
            document.getElementById('instructor_password').required = false;
            
            const modal = new bootstrap.Modal(document.getElementById('instructorModal'));
            modal.show();
        }
    } catch (error) {
        console.error('Error loading instructor:', error);
        alert('Error loading instructor data');
    }
}

async function saveInstructor() {
    try {
        const id = document.getElementById('instructor_id').value;
        const data = {
            name: document.getElementById('instructor_name').value,
            email: document.getElementById('instructor_email').value,
            phone: document.getElementById('instructor_phone').value,
            specialization: document.getElementById('instructor_specialization').value,
            status: document.getElementById('instructor_status').value || 'active',
            role: 'trainer'
        };
        
        const password = document.getElementById('instructor_password').value;
        if (password) {
            data.password = password;
        }
        
        // Validation
        if (!data.name || !data.email) {
            alert('Mohon lengkapi nama dan email');
            return;
        }
        
        if (!id && !password) {
            alert('Password wajib diisi untuk instruktur baru');
            return;
        }
        
        let response;
        if (id) {
            // Update existing user
            data.id = id;
            response = await API.post('/user-update.php', data);
        } else {
            // Create new user
            response = await API.post('/users-create.php', data);
        }
        
        if (response.success) {
            alert(response.message || 'Instruktur berhasil disimpan');
            bootstrap.Modal.getInstance(document.getElementById('instructorModal')).hide();
            await loadInstructors();
        } else {
            alert('Error: ' + (response.message || 'Gagal menyimpan instruktur'));
        }
    } catch (error) {
        console.error('Error saving instructor:', error);
        alert('Error: ' + error.message);
    }
}

async function deleteInstructor(id) {
    if (!confirm('Apakah Anda yakin ingin menghapus instruktur ini?')) {
        return;
    }
    
    try {
        const response = await API.delete(`/users.php?id=${id}`);
        if (response.success) {
            alert('Instruktur berhasil dihapus');
            await loadInstructors();
        } else {
            alert('Error: ' + (response.message || 'Gagal menghapus instruktur'));
        }
    } catch (error) {
        console.error('Error deleting instructor:', error);
        alert('Error: ' + error.message);
    }
}

// Material Management Functions
function showUploadMaterialModal() {
    document.getElementById('materialForm').reset();
    const modal = new bootstrap.Modal(document.getElementById('materialModal'));
    modal.show();
}

async function uploadMaterial() {
    try {
        const formData = new FormData();
        const fileInput = document.getElementById('material_file');
        const thumbnailInput = document.getElementById('material_thumbnail');
        
        if (!fileInput.files[0]) {
            alert('Mohon pilih file materi');
            return;
        }
        
        formData.append('title', document.getElementById('material_title').value);
        formData.append('description', document.getElementById('material_description').value);
        formData.append('category', document.getElementById('material_category').value);
        formData.append('file', fileInput.files[0]);
        
        if (thumbnailInput.files[0]) {
            formData.append('thumbnail', thumbnailInput.files[0]);
        }
        
        // Use fetch directly for FormData
        const response = await fetch(`${API.baseURL}/training/materials-upload.php`, {
            method: 'POST',
            body: formData,
            credentials: 'include'
        });
        
        const result = await response.json();
        
        if (result.success) {
            alert('Materi berhasil diupload');
            bootstrap.Modal.getInstance(document.getElementById('materialModal')).hide();
            await loadMaterials();
        } else {
            alert('Error: ' + (result.message || 'Gagal upload materi'));
        }
    } catch (error) {
        console.error('Error uploading material:', error);
        alert('Error: ' + error.message);
    }
}

function viewMaterial(id, filePath, title) {
    const viewer = document.getElementById('materialViewer');
    const viewerTitle = document.getElementById('viewerTitle');
    const downloadBtn = document.getElementById('downloadMaterialBtn');
    
    viewerTitle.textContent = title;
    downloadBtn.href = filePath;
    downloadBtn.download = title;
    
    // For PDF, use iframe directly
    if (filePath.endsWith('.pdf')) {
        viewer.src = filePath;
    } else {
        // For PPTX, use Google Docs viewer or Office Online viewer
        viewer.src = `https://view.officeapps.live.com/op/embed.aspx?src=${encodeURIComponent(window.location.origin + filePath)}`;
    }
    
    const modal = new bootstrap.Modal(document.getElementById('materialViewerModal'));
    modal.show();
}

function downloadMaterial(filePath, title) {
    const a = document.createElement('a');
    a.href = filePath;
    a.download = title;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
}

async function deleteMaterial(id) {
    if (!confirm('Apakah Anda yakin ingin menghapus materi ini?')) {
        return;
    }
    
    try {
        const response = await API.delete(`/training/materials.php?id=${id}`);
        if (response.success) {
            alert('Materi berhasil dihapus');
            await loadMaterials();
        } else {
            alert('Error: ' + (response.message || 'Gagal menghapus materi'));
        }
    } catch (error) {
        console.error('Error deleting material:', error);
        alert('Error: ' + error.message);
    }
}

// Show image modal
function showImageModal(imageUrl) {
    const modal = document.createElement('div');
    modal.className = 'modal fade';
    modal.innerHTML = `
        <div class="modal-dialog modal-lg">
            <div class="modal-content">
                <div class="modal-header">
                    <h5 class="modal-title">Training Photo</h5>
                    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
                </div>
                <div class="modal-body text-center">
                    <img src="${imageUrl}" class="img-fluid" alt="Training Photo">
                </div>
            </div>
        </div>
    `;
    
    document.body.appendChild(modal);
    const bsModal = new bootstrap.Modal(modal);
    bsModal.show();
    
    modal.addEventListener('hidden.bs.modal', function () {
        modal.remove();
    });
}

// Export session to PDF
function exportSessionPDF(sessionId) {
    window.open(`/tnd_system/tnd_system/backend-web/api/training/pdf-generate.php?session_id=${sessionId}`, '_blank');
}

// Helper functions
function formatDate(dateString) {
    if (!dateString) return '-';
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', { 
        year: 'numeric', 
        month: 'short', 
        day: 'numeric' 
    });
}

function getStatusBadge(status) {
    const badges = {
        'scheduled': '<span class="badge bg-secondary">Scheduled</span>',
        'ongoing': '<span class="badge bg-info">Ongoing</span>',
        'completed': '<span class="badge bg-success">Completed</span>',
        'cancelled': '<span class="badge bg-danger">Cancelled</span>'
    };
    return badges[status] || '<span class="badge bg-secondary">Unknown</span>';
}
