(function() {
    'use strict';

    class TimeTracker {
        constructor() {
            this.currentTime = new Date();
            this.dayMapping = {
                0: 'sun', 1: 'mon', 2: 'tue', 3: 'wed',
                4: 'thu', 5: 'fri', 6: 'sat'
            };
        }

        getCurrentDaySchedule() {
            const currentDay = this.dayMapping[this.currentTime.getDay()];
            const scheduleConfig = window.scheduleConfig;
            
            if (!scheduleConfig || !scheduleConfig.schedule) {
                return [];
            }

            return scheduleConfig.schedule.map(slot => {
                const classInfo = slot[currentDay];
                if (classInfo && classInfo !== '-') {
                    const [startTime, endTime] = this.parseTimeRange(slot.time);
                    return {
                        time: slot.time,
                        startTime,
                        endTime,
                        classInfo,
                        isPast: this.isTimePast(endTime),
                        isCurrent: this.isTimeCurrent(startTime, endTime),
                        remainingTime: this.getRemainingTime(endTime)
                    };
                }
                return null;
            }).filter(slot => slot !== null);
        }

        parseTimeRange(timeString) {
            const [start, end] = timeString.split('-');
            return [this.parseTime(start), this.parseTime(end)];
        }

        parseTime(timeString) {
            const [hours, minutes] = timeString.split(':').map(Number);
            const date = new Date(this.currentTime);
            date.setHours(hours, minutes, 0, 0);
            return date;
        }

        isTimePast(endTime) {
            return this.currentTime > endTime;
        }

        isTimeCurrent(startTime, endTime) {
            return this.currentTime >= startTime && this.currentTime <= endTime;
        }

        getRemainingTime(endTime) {
            if (this.currentTime >= endTime) return 0;
            return Math.floor((endTime - this.currentTime) / 1000 / 60); // minutes
        }

        getNextAvailableSlot() {
            const todaySchedule = this.getCurrentDaySchedule();
            const currentMinutes = this.currentTime.getHours() * 60 + this.currentTime.getMinutes();
            
            // Find next class
            for (let slot of todaySchedule) {
                if (!slot.isPast && !slot.isCurrent) {
                    const slotStartMinutes = slot.startTime.getHours() * 60 + slot.startTime.getMinutes();
                    return {
                        ...slot,
                        minutesUntilStart: slotStartMinutes - currentMinutes
                    };
                }
            }
            
            return null;
        }

        getFreeTimeUntilNextClass() {
            const nextSlot = this.getNextAvailableSlot();
            if (!nextSlot) {
                // No more classes today
                const endOfDay = new Date(this.currentTime);
                endOfDay.setHours(23, 59, 59, 999);
                return Math.floor((endOfDay - this.currentTime) / 1000 / 60);
            }
            
            return nextSlot.minutesUntilStart;
        }

        getCurrentStatus() {
            const todaySchedule = this.getCurrentDaySchedule();
            const currentClass = todaySchedule.find(slot => slot.isCurrent);
            const nextClass = this.getNextAvailableSlot();
            const freeTime = this.getFreeTimeUntilNextClass();

            return {
                currentTime: this.currentTime,
                currentDay: this.dayMapping[this.currentTime.getDay()],
                currentClass,
                nextClass,
                freeTimeMinutes: freeTime,
                todaySchedule
            };
        }

        formatMinutes(minutes) {
            if (minutes < 60) {
                return `${minutes}分`;
            }
            const hours = Math.floor(minutes / 60);
            const mins = minutes % 60;
            return mins > 0 ? `${hours}時間${mins}分` : `${hours}時間`;
        }
    }

    // グローバルに公開
    window.TimeTracker = TimeTracker;
})();