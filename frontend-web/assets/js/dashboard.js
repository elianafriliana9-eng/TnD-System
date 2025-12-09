async function showDashboard() {
    console.log('=== Dashboard Loading Started ===');
    
    // Set active menu
    try {
        if (typeof setActiveMenuItem === 'function') {
            setActiveMenuItem('Dashboard');
            console.log('✓ Menu set active');
        } else {
            console.warn('setActiveMenuItem not available');
        }
    } catch (e) {
        console.error('Error setting active menu:', e);
    }
    
    const contentArea = document.getElementById('content-area');
    if (!contentArea) {
        console.error('❌ Content area not found');
        return;
    }
    console.log('✓ Content area found');
    
    // Show loading
    try {
        if (typeof showLoading === 'function') {
            contentArea.innerHTML = showLoading();
            console.log('✓ Loading state shown');
        } else {
            contentArea.innerHTML = '<div class="text-center p-4"><i class="fas fa-spinner fa-spin"></i> Loading...</div>';
            console.log('✓ Fallback loading shown');
        }
    } catch (e) {
        console.error('Error showing loading:', e);
    }
    
    try {
        // Default stats
        let stats = {
            summary: { total_users: 0, total_outlets: 0, total_categories: 0, total_divisions: 0 },
            recent_audits: [],
            audit_trends: [],
            visit_stats: null
        };

        // Try to load from API
        try {
            console.log('📡 Calling API...');
            const response = await API.get('/dashboard-stats.php');
            console.log('📊 API Response:', response);
            
            if (response && response.success && response.data) {
                stats = { ...stats, ...response.data };
                console.log('✓ Stats loaded from API:', stats);
            } else {
                console.warn('⚠️ API response structure unexpected:', response);
            }
        } catch (apiError) {
            console.error('❌ API Error:', apiError.message);
            console.warn('Using default stats due to API error');
        }
        
        // Load visit statistics
        try {
            console.log('📡 Calling Visit Stats API...');
            const visitResponse = await API.get('/visit-stats.php');
            console.log('📊 Visit Stats Response:', visitResponse);
            
            if (visitResponse && visitResponse.success && visitResponse.data) {
                stats.visit_stats = visitResponse.data;
                console.log('✓ Visit stats loaded:', stats.visit_stats);
            }
        } catch (visitError) {
            console.error('❌ Visit Stats API Error:', visitError.message);
        }
        
        const dashboardHTML = `
            <div class="fade-in">
                <!-- Header Section -->
                <div class="dashboard-header mb-4">
                    <div>
                        <h2 class="mb-1" style="font-weight: 600; color: #1a1a1a;">Welcome Back! 👋</h2>
                        <p class="text-muted mb-0">Here's what's happening with your system today.</p>
                    </div>
                    <div class="text-end">
                        <span class="badge bg-light text-dark px-3 py-2" style="font-size: 0.9rem;">
                            <i class="fas fa-calendar-day me-2"></i>${new Date().toLocaleDateString('id-ID', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })}
                        </span>
                    </div>
                </div>

                <!-- Stats Cards - Clean Minimal Design -->
                <div class="row g-3 mb-4">
                    <div class="col-md-3">
                        <div class="stat-card-clean">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                                <i class="fas fa-users"></i>
                            </div>
                            <div class="stat-details">
                                <h3 class="stat-number">${stats.summary.total_users}</h3>
                                <p class="stat-label">Total Users</p>
                                <span class="stat-change text-success">
                                    <i class="fas fa-arrow-up"></i> Active
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stat-card-clean">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                                <i class="fas fa-store"></i>
                            </div>
                            <div class="stat-details">
                                <h3 class="stat-number">${stats.summary.total_outlets}</h3>
                                <p class="stat-label">Total Outlets</p>
                                <span class="stat-change text-success">
                                    <i class="fas fa-arrow-up"></i> Active
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stat-card-clean">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                                <i class="fas fa-list"></i>
                            </div>
                            <div class="stat-details">
                                <h3 class="stat-number">${stats.summary.total_categories}</h3>
                                <p class="stat-label">Categories</p>
                                <span class="stat-change text-info">
                                    <i class="fas fa-check"></i> Active
                                </span>
                            </div>
                        </div>
                    </div>
                    <div class="col-md-3">
                        <div class="stat-card-clean">
                            <div class="stat-icon" style="background: linear-gradient(135deg, #43e97b 0%, #38f9d7 100%);">
                                <i class="fas fa-clipboard-check"></i>
                            </div>
                            <div class="stat-details">
                                <h3 class="stat-number">${stats.visit_stats ? stats.visit_stats.total_visits : 0}</h3>
                                <p class="stat-label">Total Visits</p>
                                <span class="stat-change text-success">
                                    <i class="fas fa-chart-line"></i> Tracking
                                </span>
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Charts & Recent Activities -->
                <div class="row g-3">
                    <div class="col-md-8">
                        <div class="card-clean">
                            <div class="card-clean-header">
                                <div>
                                    <h5 class="mb-1" style="font-weight: 600;">📊 Daily Visits Trend</h5>
                                    <p class="text-muted small mb-0">Last 7 days performance per division</p>
                                </div>
                                <div class="dropdown">
                                    <button class="btn btn-sm btn-light" type="button" data-bs-toggle="dropdown">
                                        <i class="fas fa-ellipsis-v"></i>
                                    </button>
                                    <ul class="dropdown-menu dropdown-menu-end">
                                        <li><a class="dropdown-item" href="#"><i class="fas fa-download me-2"></i>Export Data</a></li>
                                        <li><a class="dropdown-item" href="#"><i class="fas fa-print me-2"></i>Print Chart</a></li>
                                    </ul>
                                </div>
                            </div>
                            <div class="card-clean-body">
                                <div style="position: relative; height: 320px;">
                                    <canvas id="auditTrendChart"></canvas>
                                </div>
                            </div>
                        </div>
                    </div>
                    
                    <div class="col-md-4">
                        <div class="card-clean">
                            <div class="card-clean-header">
                                <div>
                                    <h5 class="mb-1" style="font-weight: 600;">🕐 Recent Visits</h5>
                                    <p class="text-muted small mb-0">Latest visit activities</p>
                                </div>
                            </div>
                            <div class="card-clean-body" style="max-height: 360px; overflow-y: auto;" id="recentActivitiesList">
                                <!-- Recent activities will be rendered here by JS -->
                            </div>
                        </div>
                    </div>
                </div>
                
                <!-- Quick Actions -->
                <div class="row g-3 mt-2">
                    <div class="col-md-12">
                        <div class="card-clean">
                            <div class="card-clean-header">
                                <div>
                                    <h5 class="mb-1" style="font-weight: 600;">⚡ Quick Actions</h5>
                                    <p class="text-muted small mb-0">Manage your system efficiently</p>
                                </div>
                            </div>
                            <div class="card-clean-body">
                                <div class="row g-3">
                                    <div class="col-md-3">
                                        <button class="btn-action-card" onclick="showUsers()">
                                            <div class="action-icon" style="background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);">
                                                <i class="fas fa-users"></i>
                                            </div>
                                            <h6 class="mt-3 mb-1">Manage Users</h6>
                                            <p class="text-muted small mb-0">Add, edit or delete users</p>
                                        </button>
                                    </div>
                                    <div class="col-md-3">
                                        <button class="btn-action-card" onclick="showOutlets()">
                                            <div class="action-icon" style="background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%);">
                                                <i class="fas fa-store"></i>
                                            </div>
                                            <h6 class="mt-3 mb-1">Manage Outlets</h6>
                                            <p class="text-muted small mb-0">View and edit outlets</p>
                                        </button>
                                    </div>
                                    <div class="col-md-3">
                                        <button class="btn-action-card" onclick="showChecklistManagement()">
                                            <div class="action-icon" style="background: linear-gradient(135deg, #4facfe 0%, #00f2fe 100%);">
                                                <i class="fas fa-clipboard-list"></i>
                                            </div>
                                            <h6 class="mt-3 mb-1">Checklist Setup</h6>
                                            <p class="text-muted small mb-0">Configure checklist items</p>
                                        </button>
                                    </div>
                                    <div class="col-md-3">
                                        <button class="btn-action-card" onclick="showReports()">
                                            <div class="action-icon" style="background: linear-gradient(135deg, #fa709a 0%, #fee140 100%);">
                                                <i class="fas fa-chart-bar"></i>
                                            </div>
                                            <h6 class="mt-3 mb-1">View Reports</h6>
                                            <p class="text-muted small mb-0">Analytics and insights</p>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
        
        console.log('🎨 Rendering dashboard HTML...');
        contentArea.innerHTML = dashboardHTML;

        // Render dynamic content - use daily trends if available
        const trendsToRender = stats.visit_stats && stats.visit_stats.daily_trends 
            ? stats.visit_stats.daily_trends 
            : null;
        renderDailyTrendChart(trendsToRender);
        
        // Render recent visits if available, otherwise recent audits
        const activitiesToRender = stats.visit_stats && stats.visit_stats.recent_visits 
            ? stats.visit_stats.recent_visits 
            : stats.recent_audits;
        renderRecentActivities(activitiesToRender);

        console.log('✅ Dashboard rendered successfully!');
        
    } catch (error) {
        console.error('❌ Dashboard Error:', error);
        console.error('Error stack:', error.stack);
        
        contentArea.innerHTML = `
            <div class="alert alert-danger">
                <i class="fas fa-exclamation-triangle me-2"></i>
                <strong>Error loading dashboard:</strong> ${error.message}<br>
                <small>Check console for details</small>
                <button class="btn btn-sm btn-outline-danger ms-2" onclick="showDashboard()">Retry</button>
            </div>
        `;
    }
}

function renderDailyTrendChart(dailyData) {
    const ctx = document.getElementById('auditTrendChart');
    if (!ctx || !dailyData) {
        console.warn('Chart canvas or daily data not available.');
        return;
    }

    // Set canvas parent height explicitly
    if (ctx.parentElement) {
        ctx.parentElement.style.height = '350px';
        ctx.parentElement.style.maxHeight = '350px';
    }

    if (!dailyData.days || dailyData.days.length === 0) {
        ctx.parentElement.innerHTML = `
            <div class="text-center text-muted py-5">
                <i class="fas fa-chart-line fa-3x mb-3"></i>
                <p>No visit data available for the last 7 days.</p>
            </div>`;
        return;
    }

    // Prepare datasets for each division
    const colors = [
        { bg: 'rgba(75, 192, 192, 0.2)', border: 'rgba(75, 192, 192, 1)' },
        { bg: 'rgba(255, 99, 132, 0.2)', border: 'rgba(255, 99, 132, 1)' },
        { bg: 'rgba(54, 162, 235, 0.2)', border: 'rgba(54, 162, 235, 1)' },
        { bg: 'rgba(255, 206, 86, 0.2)', border: 'rgba(255, 206, 86, 1)' },
        { bg: 'rgba(153, 102, 255, 0.2)', border: 'rgba(153, 102, 255, 1)' },
        { bg: 'rgba(255, 159, 64, 0.2)', border: 'rgba(255, 159, 64, 1)' }
    ];

    const datasets = dailyData.divisions.map((division, index) => {
        const colorIndex = index % colors.length;
        const divisionData = [];
        
        // Map data for each day
        dailyData.dates.forEach(date => {
            divisionData.push(dailyData.data[division][date] || 0);
        });

        return {
            label: division,
            data: divisionData,
            backgroundColor: colors[colorIndex].bg,
            borderColor: colors[colorIndex].border,
            borderWidth: 3,
            tension: 0.4,
            fill: false,
            pointRadius: 5,
            pointHoverRadius: 7,
            pointBackgroundColor: colors[colorIndex].border,
            pointBorderColor: '#fff',
            pointBorderWidth: 2
        };
    });

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: dailyData.days,
            datasets: datasets
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + context.parsed.y + ' visits';
                        }
                    }
                }
            }
        }
    });
}

function renderWeeklyTrendChart(weeklyData) {
    const ctx = document.getElementById('auditTrendChart');
    if (!ctx || !weeklyData) {
        console.warn('Chart canvas or weekly data not available.');
        return;
    }

    // Set canvas parent height explicitly
    if (ctx.parentElement) {
        ctx.parentElement.style.height = '350px';
        ctx.parentElement.style.maxHeight = '350px';
    }

    if (!weeklyData.weeks || weeklyData.weeks.length === 0) {
        ctx.parentElement.innerHTML = `
            <div class="text-center text-muted py-5">
                <i class="fas fa-chart-line fa-3x mb-3"></i>
                <p>No visit data available for the last 4 weeks.</p>
            </div>`;
        return;
    }

    // Prepare datasets for each division
    const colors = [
        { bg: 'rgba(75, 192, 192, 0.2)', border: 'rgba(75, 192, 192, 1)' },
        { bg: 'rgba(255, 99, 132, 0.2)', border: 'rgba(255, 99, 132, 1)' },
        { bg: 'rgba(54, 162, 235, 0.2)', border: 'rgba(54, 162, 235, 1)' },
        { bg: 'rgba(255, 206, 86, 0.2)', border: 'rgba(255, 206, 86, 1)' },
        { bg: 'rgba(153, 102, 255, 0.2)', border: 'rgba(153, 102, 255, 1)' },
        { bg: 'rgba(255, 159, 64, 0.2)', border: 'rgba(255, 159, 64, 1)' }
    ];

    const datasets = weeklyData.divisions.map((division, index) => {
        const colorIndex = index % colors.length;
        const divisionData = [];
        
        weeklyData.weeks.forEach(week => {
            divisionData.push(weeklyData.data[division][week] || 0);
        });

        return {
            label: division,
            data: divisionData,
            backgroundColor: colors[colorIndex].bg,
            borderColor: colors[colorIndex].border,
            borderWidth: 3,
            tension: 0.4,
            fill: false,
            pointRadius: 5,
            pointHoverRadius: 7,
            pointBackgroundColor: colors[colorIndex].border,
            pointBorderColor: '#fff',
            pointBorderWidth: 2
        };
    });

    new Chart(ctx, {
        type: 'line',
        data: {
            labels: weeklyData.weeks,
            datasets: datasets
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            interaction: {
                mode: 'index',
                intersect: false,
            },
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            },
            plugins: {
                legend: {
                    display: true,
                    position: 'top',
                },
                tooltip: {
                    callbacks: {
                        label: function(context) {
                            return context.dataset.label + ': ' + context.parsed.y + ' visits';
                        }
                    }
                }
            }
        }
    });
}

function renderAuditTrendChart(trendData) {
    const ctx = document.getElementById('auditTrendChart');
    if (!ctx || !trendData) {
        console.warn('Chart canvas or trend data not available.');
        return;
    }

    // Set canvas parent height explicitly
    if (ctx.parentElement) {
        ctx.parentElement.style.height = '350px';
        ctx.parentElement.style.maxHeight = '350px';
    }

    if (trendData.length === 0) {
        ctx.parentElement.innerHTML = `
            <div class="text-center text-muted py-5">
                <i class="fas fa-chart-line fa-3x mb-3"></i>
                <p>No audit data available to display chart.</p>
            </div>`;
        return;
    }

    const labels = trendData.map(d => {
        const [year, month] = d.month.split('-');
        return new Date(year, month - 1).toLocaleString('default', { month: 'short', year: 'numeric' });
    });
    const data = trendData.map(d => d.count);

    new Chart(ctx, {
        type: 'bar',
        data: {
            labels: labels,
            datasets: [{
                label: 'Visits Completed',
                data: data,
                backgroundColor: 'rgba(75, 192, 192, 0.5)',
                borderColor: 'rgba(75, 192, 192, 1)',
                borderWidth: 1,
                borderRadius: 5
            }]
        },
        options: {
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                y: {
                    beginAtZero: true,
                    ticks: {
                        stepSize: 1
                    }
                }
            },
            plugins: {
                legend: {
                    display: false
                }
            }
        }
    });
}

function renderRecentActivities(activities) {
    const container = document.getElementById('recentActivitiesList');
    if (!container || !activities) {
        console.warn('Recent activities container or data not available.');
        return;
    }

    if (activities.length === 0) {
        container.innerHTML = `
            <div class="text-center text-muted py-5">
                <i class="fas fa-clock fa-3x mb-3"></i>
                <p>No recent activities found.</p>
            </div>`;
        return;
    }

    let activitiesHTML = '<ul class="list-group list-group-flush">';
    activities.forEach(activity => {
        const activityDate = new Date(activity.visit_date || activity.created_at).toLocaleDateString('en-CA', { year: 'numeric', month: 'short', day: 'numeric' });
        const activityOutlet = activity.outlet_name || 'N/A';
        const activityUser = activity.auditor_name || activity.user_name || 'N/A';
        const activityScore = activity.score !== undefined ? `${activity.score}%` : '';
        
        activitiesHTML += `
            <li class="list-group-item d-flex justify-content-between align-items-start">
                <div class="ms-2 me-auto">
                    <div class="fw-bold">${activityOutlet}</div>
                    <small class="text-muted">by ${activityUser}</small>
                    ${activityScore ? `<br><small class="text-success">${activityScore}</small>` : ''}
                </div>
                <span class="badge bg-primary rounded-pill">${activityDate}</span>
            </li>
        `;
    });
    activitiesHTML += '</ul>';

    container.innerHTML = activitiesHTML;
}