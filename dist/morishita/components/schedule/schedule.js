(function() {
    'use strict';

    let timeTracker = null;
    let updateInterval = null;

    function initSchedule() {
        const scheduleSection = document.querySelector('.schedule-section');
        const classItems = document.querySelectorAll('.class-item');

        if (!scheduleSection) return;

        // セクションヘッダーのアニメーション初期化
        initSectionHeaderAnimation();

        // 設定の適用
        if (window.scheduleConfig) {
            applyScheduleConfig(window.scheduleConfig);
        }

        // タイムトラッカーの初期化
        if (window.TimeTracker) {
            timeTracker = new window.TimeTracker();
            initTimeTracking();
        }

        // クラスアイテムのホバーエフェクト
        classItems.forEach(item => {
            item.addEventListener('mouseenter', function() {
                this.style.transform = 'scale(1.05)';
                this.style.cursor = 'pointer';
            });

            item.addEventListener('mouseleave', function() {
                this.style.transform = 'scale(1)';
            });

            item.addEventListener('click', function() {
                const contactSection = document.querySelector('#contact');
                if (contactSection) {
                    contactSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
                }
            });
        });

        // テーブルのレスポンシブ対応
        handleTableResponsive();
    }

    function applyScheduleConfig(config) {
        if (!config) return;

        // グローバルに公開（TimeTracker用）
        window.scheduleConfig = config;

        // スケジュールデータの更新
        if (config.schedule && Array.isArray(config.schedule)) {
            updateScheduleTable(config.schedule);
        }

        // 凡例の更新
        if (config.classTypes && Array.isArray(config.classTypes)) {
            updateLegend(config.classTypes);
        }

        // 注記の更新
        if (config.notes && Array.isArray(config.notes)) {
            const notesContainer = document.querySelector('.schedule-notes');
            if (notesContainer) {
                notesContainer.innerHTML = '';
                
                config.notes.forEach(note => {
                    const p = document.createElement('p');
                    p.textContent = note;
                    notesContainer.appendChild(p);
                });
            }
        }
    }

    function updateScheduleTable(scheduleData) {
        const tbody = document.querySelector('.schedule-table tbody');
        if (!tbody) return;

        tbody.innerHTML = '';

        scheduleData.forEach(row => {
            const tr = document.createElement('tr');
            
            // 時間
            const timeCell = document.createElement('td');
            timeCell.className = 'time';
            timeCell.textContent = row.time;
            tr.appendChild(timeCell);

            // 各曜日のクラス
            ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'].forEach(day => {
                const td = document.createElement('td');
                const classInfo = row[day];
                
                if (classInfo && classInfo !== '-') {
                    const classItem = document.createElement('div');
                    classItem.className = `class-item ${classInfo.type}`;
                    classItem.textContent = classInfo.name;
                    td.appendChild(classItem);
                } else {
                    td.textContent = '-';
                }
                
                tr.appendChild(td);
            });

            tbody.appendChild(tr);
        });
    }

    function updateLegend(classTypes) {
        const legendGrid = document.querySelector('.legend-grid');
        if (!legendGrid) return;

        legendGrid.innerHTML = '';

        classTypes.forEach(type => {
            const item = document.createElement('div');
            item.className = 'legend-item';

            const color = document.createElement('span');
            color.className = `legend-color ${type.class}`;

            const text = document.createElement('span');
            text.textContent = type.name;

            item.appendChild(color);
            item.appendChild(text);
            legendGrid.appendChild(item);
        });
    }

    function handleTableResponsive() {
        const tableWrapper = document.querySelector('.schedule-table-wrapper');
        if (!tableWrapper) return;

        let isDown = false;
        let startX;
        let scrollLeft;

        tableWrapper.addEventListener('mousedown', (e) => {
            isDown = true;
            tableWrapper.style.cursor = 'grabbing';
            startX = e.pageX - tableWrapper.offsetLeft;
            scrollLeft = tableWrapper.scrollLeft;
        });

        tableWrapper.addEventListener('mouseleave', () => {
            isDown = false;
            tableWrapper.style.cursor = 'grab';
        });

        tableWrapper.addEventListener('mouseup', () => {
            isDown = false;
            tableWrapper.style.cursor = 'grab';
        });

        tableWrapper.addEventListener('mousemove', (e) => {
            if (!isDown) return;
            e.preventDefault();
            const x = e.pageX - tableWrapper.offsetLeft;
            const walk = (x - startX) * 2;
            tableWrapper.scrollLeft = scrollLeft - walk;
        });
    }

    function initTimeTracking() {
        createTimeDisplay();
        updateTimeDisplay();
        
        // 1分ごとに更新
        updateInterval = setInterval(updateTimeDisplay, 60000);
        
        // 今日のスケジュールをハイライト
        highlightTodaySchedule();
    }

    function createTimeDisplay() {
        const scheduleSection = document.querySelector('.schedule-section');
        if (!scheduleSection) return;

        // 既存のパネルがあれば削除
        const existingPanel = scheduleSection.querySelector('.time-tracking-panel');
        if (existingPanel) {
            existingPanel.remove();
        }

        // 時間表示パネルを作成
        const timePanel = document.createElement('div');
        timePanel.className = 'time-tracking-panel';
        timePanel.innerHTML = `
            <div class="current-time-display">
                <h3>現在の時刻</h3>
                <div class="time-info">
                    <span class="current-time"></span>
                    <span class="current-day"></span>
                </div>
            </div>
            <div class="time-status">
                <div class="current-class-info"></div>
                <div class="next-class-info"></div>
                <div class="free-time-info"></div>
            </div>
        `;
        
        // schedule-containerの中のsection-headerを探す
        const scheduleContainer = scheduleSection.querySelector('.schedule-container');
        if (scheduleContainer) {
            const sectionHeader = scheduleContainer.querySelector('.section-header');
            if (sectionHeader && sectionHeader.parentNode) {
                // section-headerの次に挿入
                sectionHeader.parentNode.insertBefore(timePanel, sectionHeader.nextSibling);
            } else {
                // section-headerがない場合は、schedule-containerの最初に追加
                scheduleContainer.insertBefore(timePanel, scheduleContainer.firstChild);
            }
        }
    }

    function updateTimeDisplay() {
        if (!timeTracker) return;

        const status = timeTracker.getCurrentStatus();
        const currentTimeEl = document.querySelector('.current-time');
        const currentDayEl = document.querySelector('.current-day');
        const currentClassEl = document.querySelector('.current-class-info');
        const nextClassEl = document.querySelector('.next-class-info');
        const freeTimeEl = document.querySelector('.free-time-info');

        if (currentTimeEl) {
            const hours = status.currentTime.getHours();
            const minutes = status.currentTime.getMinutes();
            currentTimeEl.textContent = `${hours}:${minutes.toString().padStart(2, '0')}`;
        }

        if (currentDayEl) {
            const days = ['日曜日', '月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日'];
            currentDayEl.textContent = days[status.currentTime.getDay()];
        }

        if (currentClassEl) {
            if (status.currentClass) {
                currentClassEl.innerHTML = `
                    <div class="status-item current">
                        <span class="status-label">現在のクラス:</span>
                        <span class="class-name">${status.currentClass.classInfo.name}</span>
                        <span class="remaining-time">残り ${status.currentClass.remainingTime}分</span>
                    </div>
                `;
            } else {
                currentClassEl.innerHTML = '';
            }
        }

        if (nextClassEl) {
            if (status.nextClass) {
                nextClassEl.innerHTML = `
                    <div class="status-item next">
                        <span class="status-label">次のクラス:</span>
                        <span class="class-name">${status.nextClass.classInfo.name}</span>
                        <span class="start-time">${status.nextClass.time.split('-')[0]}開始</span>
                    </div>
                `;
            } else {
                nextClassEl.innerHTML = `
                    <div class="status-item">
                        <span class="status-label">本日のクラスは終了しました</span>
                    </div>
                `;
            }
        }

        if (freeTimeEl) {
            const freeTimeFormatted = timeTracker.formatMinutes(status.freeTimeMinutes);
            if (!status.currentClass) {
                freeTimeEl.innerHTML = `
                    <div class="status-item free-time">
                        <span class="status-label">次のクラスまで:</span>
                        <span class="time-amount">${freeTimeFormatted}</span>
                    </div>
                `;
            } else {
                freeTimeEl.innerHTML = '';
            }
        }
    }

    function highlightTodaySchedule() {
        if (!timeTracker) return;

        const status = timeTracker.getCurrentStatus();
        const dayIndex = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'].indexOf(status.currentDay);
        
        if (dayIndex === -1) return;

        // 今日の列をハイライト
        const table = document.querySelector('.schedule-table');
        if (table) {
            const headerCells = table.querySelectorAll('thead th');
            const bodyCells = table.querySelectorAll('tbody td');
            
            // ヘッダーのハイライト
            if (headerCells[dayIndex + 1]) {
                headerCells[dayIndex + 1].classList.add('today-column');
            }

            // ボディのハイライト
            const rows = table.querySelectorAll('tbody tr');
            rows.forEach(row => {
                const cells = row.querySelectorAll('td');
                if (cells[dayIndex + 1]) {
                    cells[dayIndex + 1].classList.add('today-column');
                }
            });

            // 現在進行中のクラスをハイライト
            status.todaySchedule.forEach((slot, index) => {
                if (slot.isCurrent) {
                    const currentRow = rows[index];
                    if (currentRow) {
                        const currentCell = currentRow.querySelectorAll('td')[dayIndex + 1];
                        if (currentCell) {
                            const classItem = currentCell.querySelector('.class-item');
                            if (classItem) {
                                classItem.classList.add('current-class');
                            }
                        }
                    }
                }
            });
        }
    }

    // セクションヘッダーのアニメーション
    function initSectionHeaderAnimation() {
        const headerObserver = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('animate-in');
                }
            });
        }, {
            threshold: 0.2,
            rootMargin: '0px 0px -50px 0px'
        });

        const header = document.querySelector('.schedule-section .section-header');
        if (header) {
            // 初期状態を設定
            header.style.opacity = '0';
            header.style.transform = 'translateY(40px)';
            header.style.transition = 'opacity 1.2s cubic-bezier(0.25, 0.46, 0.45, 0.94), transform 1.2s cubic-bezier(0.25, 0.46, 0.45, 0.94)';
            
            headerObserver.observe(header);
        }

        // animate-inクラスが追加されたときのスタイル適用
        const style = document.createElement('style');
        style.textContent = `
            .schedule-section .section-header.animate-in {
                opacity: 1 !important;
                transform: translateY(0) !important;
            }
        `;
        document.head.appendChild(style);
    }

    // DOMが読み込まれたら初期化
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', initSchedule);
    } else {
        initSchedule();
    }

    // クリーンアップ
    window.addEventListener('beforeunload', () => {
        if (updateInterval) {
            clearInterval(updateInterval);
        }
    });
})();