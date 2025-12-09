// Training Reports JavaScript
let currentDetailSessionId = null;

// Load on page ready
document.addEventListener('DOMContentLoaded', function() {
    loadOutlets();
    loadReports();
    
    // Setup filter form
    document.getElementById('filterForm').addEventListener('submit', function(e) {
        e.preventDefault();
        loadReports();
    });
});

// Load outlets for filter
async function loadOutlets() {
    try {
        const response = await API.get('/outlets.php');
        if (response.success && response.data) {
            const select = document.getElementById('filterOutlet');
            response.data.forEach(outlet => {
                const option = document.createElement('option');
                option.value = outlet.id;
                option.textContent = outlet.name;
                select.appendChild(option);
            });
        }
    } catch (error) {
        console.error('Error loading outlets:', error);
    }
}

// Load training reports
async function loadReports() {
    const tbody = document.getElementById('reportsTableBody');
    tbody.innerHTML = '<tr><td colspan="7" class="text-center"><div class="spinner-border text-primary" role="status"></div></td></tr>';
    
    try {
        // Build query params
        const params = new URLSearchParams();
        const startDate = document.getElementById('startDate').value;
        const endDate = document.getElementById('endDate').value;
        const outlet = document.getElementById('filterOutlet').value;
        const status = document.getElementById('filterStatus').value;
        
        if (startDate) params.append('start_date', startDate);
        if (endDate) params.append('end_date', endDate);
        if (outlet) params.append('outlet_id', outlet);
        if (status) params.append('status', status);
        
        const response = await API.get(`/training/sessions.php?${params.toString()}`);
        
        if (response.success && response.data) {
            displayReports(response.data);
        } else {
            tbody.innerHTML = '<tr><td colspan="7" class="text-center text-danger">Gagal memuat data</td></tr>';
        }
    } catch (error) {
        console.error('Error loading reports:', error);
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-danger">Error: ' + error.message + '</td></tr>';
    }
}

// Display reports in table
function displayReports(sessions) {
    const tbody = document.getElementById('reportsTableBody');
    
    if (!sessions || sessions.length === 0) {
        tbody.innerHTML = '<tr><td colspan="7" class="text-center text-muted">Tidak ada data</td></tr>';
        return;
    }
    
    tbody.innerHTML = sessions.map(session => {
        const statusBadge = getStatusBadge(session.status);
        const score = session.average_score ? parseFloat(session.average_score).toFixed(2) : '-';
        const scoreClass = getScoreClass(session.average_score);
        
        return `
            <tr>
                <td>${formatDate(session.session_date)}</td>
                <td>${session.outlet?.name || 'N/A'}</td>
                <td>${session.checklist?.name || 'N/A'}</td>
                <td>${session.trainer?.name || 'N/A'}</td>
                <td>${statusBadge}</td>
                <td><span class="badge ${scoreClass}">${score}</span></td>
                <td>
                    <button class="btn btn-sm btn-primary" onclick="viewDetail(${session.id})">
                        <i class="fas fa-eye"></i> Detail
                    </button>
                    ${session.status === 'completed' ? `
                        <button class="btn btn-sm btn-danger" onclick="downloadPDF(${session.id})">
                            <i class="fas fa-file-pdf"></i>
                        </button>
                    ` : ''}
                </td>
            </tr>
        `;
    }).join('');
}

// View report detail
async function viewDetail(sessionId) {
    currentDetailSessionId = sessionId;
    const modalBody = document.getElementById('detailModalBody');
    modalBody.innerHTML = '<div class="text-center"><div class="spinner-border text-primary" role="status"></div></div>';
    
    const modal = new bootstrap.Modal(document.getElementById('detailModal'));
    modal.show();
    
    try {
        const response = await API.get(`/training/pdf-data.php?session_id=${sessionId}`);
        
        if (response.success && response.data) {
            displayDetail(response.data);
        } else {
            modalBody.innerHTML = '<div class="alert alert-danger">Gagal memuat detail</div>';
        }
    } catch (error) {
        console.error('Error loading detail:', error);
        modalBody.innerHTML = '<div class="alert alert-danger">Error: ' + error.message + '</div>';
    }
}

// Display detail in modal
function displayDetail(data) {
    const modalBody = document.getElementById('detailModalBody');
    
    let html = `
        <div class="row mb-4">
            <div class="col-md-6">
                <h6>Informasi Training</h6>
                <table class="table table-sm">
                    <tr><td width="150"><strong>Outlet</strong></td><td>${data.outlet.name}</td></tr>
                    <tr><td><strong>Alamat</strong></td><td>${data.outlet.address || '-'}</td></tr>
                    <tr><td><strong>Tanggal</strong></td><td>${formatDate(data.session_date)}</td></tr>
                    <tr><td><strong>Waktu</strong></td><td>${data.start_time} - ${data.end_time || '-'}</td></tr>
                    <tr><td><strong>Trainer</strong></td><td>${data.trainer.name}</td></tr>
                </table>
            </div>
            <div class="col-md-6">
                <h6>Ringkasan Penilaian</h6>
                ${data.rating_summary ? `
                    <div class="alert alert-info">
                        <p><strong>Total Point:</strong> ${data.rating_summary.total_points}</p>
                        <p><strong>Baik:</strong> ${data.rating_summary.baik.count} (${data.rating_summary.baik.percentage}%)</p>
                        <p><strong>Cukup:</strong> ${data.rating_summary.cukup.count} (${data.rating_summary.cukup.percentage}%)</p>
                        <p><strong>Kurang:</strong> ${data.rating_summary.kurang.count} (${data.rating_summary.kurang.percentage}%)</p>
                        <p><strong>Skor Rata-rata:</strong> ${parseFloat(data.average_score).toFixed(2)}</p>
                    </div>
                ` : '<p class="text-muted">Belum ada penilaian</p>'}
            </div>
        </div>
    `;
    
    // Evaluations
    if (data.evaluations && data.evaluations.length > 0) {
        html += '<h6>Hasil Evaluasi</h6>';
        
        // Group by category
        const categories = {};
        data.evaluations.forEach(evaluation => {
            if (!categories[evaluation.category_name]) {
                categories[evaluation.category_name] = [];
            }
            categories[evaluation.category_name].push(evaluation);
        });
        
        Object.keys(categories).forEach(catName => {
            html += `<h6 class="mt-3">${catName}</h6>`;
            html += '<table class="table table-sm table-bordered">';
            html += '<thead><tr><th>No</th><th>Point</th><th>Rating</th><th>Catatan</th></tr></thead><tbody>';
            
            categories[catName].forEach((evaluation, idx) => {
                const ratingClass = getRatingClass(evaluation.rating);
                html += `
                    <tr>
                        <td>${idx + 1}</td>
                        <td>${evaluation.point_text}</td>
                        <td><span class="badge ${ratingClass}">${evaluation.rating.toUpperCase()}</span></td>
                        <td>${evaluation.notes || '-'}</td>
                    </tr>
                `;
            });
            
            html += '</tbody></table>';
        });
    }
    
    // Training topics
    if (data.topics && data.topics.length > 0) {
        html += '<h6 class="mt-4">Materi Training</h6><ol>';
        data.topics.forEach(topic => {
            html += `<li>${topic}</li>`;
        });
        html += '</ol>';
    }
    
    // Signatures
    if (data.signatures && data.signatures.length > 0) {
        html += '<h6 class="mt-4">Tanda Tangan</h6>';
        html += '<div class="row">';
        data.signatures.forEach(sig => {
            html += `
                <div class="col-md-4 text-center">
                    <p><strong>${sig.role.toUpperCase()}</strong></p>
                    <div style="min-height: 60px;"></div>
                    <p style="border-top: 1px solid #000; padding-top: 5px;">
                        <strong>${sig.name}</strong><br>
                        ${sig.position}
                    </p>
                </div>
            `;
        });
        html += '</div>';
    }
    
    modalBody.innerHTML = html;
}

// Download PDF
function downloadPDF(sessionId = null) {
    const id = sessionId || currentDetailSessionId;
    if (!id) return;
    
    window.open(`/tnd_system/tnd_system/backend-web/api/training/pdf-generate.php?session_id=${id}`, '_blank');
}

// Helper functions
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' });
}

function getStatusBadge(status) {
    const badges = {
        'completed': '<span class="badge bg-success">Selesai</span>',
        'ongoing': '<span class="badge bg-warning">Berlangsung</span>',
        'pending': '<span class="badge bg-secondary">Pending</span>',
        'cancelled': '<span class="badge bg-danger">Dibatalkan</span>'
    };
    return badges[status] || '<span class="badge bg-secondary">Unknown</span>';
}

function getScoreClass(score) {
    if (!score) return 'bg-secondary';
    score = parseFloat(score);
    if (score >= 80) return 'bg-success';
    if (score >= 60) return 'bg-warning';
    return 'bg-danger';
}

function getRatingClass(rating) {
    const classes = {
        'baik': 'bg-success',
        'cukup': 'bg-warning',
        'kurang': 'bg-danger'
    };
    return classes[rating] || 'bg-secondary';
}

function resetFilters() {
    document.getElementById('startDate').value = '';
    document.getElementById('endDate').value = '';
    document.getElementById('filterOutlet').value = '';
    document.getElementById('filterStatus').value = '';
    loadReports();
}

async function exportToExcel() {
    alert('Export Excel feature coming soon!');
}
