# Strict Workflow & Cross-Day Testing Checklist

Use this checklist to verify the latest updates to the Equipment Operation module, focusing on cross-day logic and strict sequential flow.

## 1. Start Operation (New Feature)
- [ ] **Open Start Screen**: Tap the + button to start a new operation.
- [ ] **Select Equipment**: Choose an equipment from the dropdown.
- [ ] **Auto-Fill Check**:
  - [ ] **Last HM**: Verify the "HM Start" field **automatically populates** with the last known value (2 decimals).
  - [ ] If no previous data, it should default to 0.00 or remain empty/editable.
- [ ] **Submit**: Take photo and start operation.

## 2. Task Creation (Add Task)
- [ ] **Open Add Task Sheet**: Navigate to an ongoing operation and tap "+" (Add Task).
- [ ] **Verify Fields**:
  - [ ] **Finish Later Toggle**: Should be **GONE**.
  - [ ] **End Time**: Should be **GONE**.
  - [ ] **Instructed By**: Should auto-select **Organization ID 1** (if available).
- [ ] **Submit Task**:
  - [ ] Tap "Start Task".
  - [ ] **Validation**: Button should disable immediately to prevent duplicate clicks.

## 3. Finish Task (Cross-Day Logic)
- [ ] **Scenario**: Start a task at **23:00 (11:00 PM)**.
- [ ] **Open Finish Screen**: Tap "Finish" on the ongoing task.
- [ ] **Input End Time**: Select **01:00 (1:00 AM)** (which is technically "before" 23:00 on the clock face).
- [ ] **Visual Check**:
  - [ ] Display should show `01:00 (+1 Day)`.
- [ ] **Logic Check**:
  - [ ] Tap Finish. App should accept this as valid (2 hours duration).
  - [ ] App should **NOT** show "End time must be after start time" error.
- [ ] **Max Duration Check**:
  - [ ] Try inputting **06:00 (+1 Day)** (7 hours duration).
  - [ ] Tap Finish.
  - [ ] **Result**: Should show error: "Task duration cannot exceed 6 hours".

## 4. Finish Task (Decimal Precision)
- [ ] **HM Logic**:
  - [ ] Verify HM End field is **pre-filled** with HM Start value (2 decimals).
  - [ ] Enter `1234.569`. It should round/truncate or just behave as number.
  - [ ] Verify display uses 2 decimal places always (e.g. `1234.50` not `1234.5`).

## 5. Finish Operation Restrictions
- [ ] **Blocking Logic**:
  - [ ] Start a new task.
  - [ ] Tap "Finish Operation".
  - [ ] **Result**: Dialog appears "Please finish all ongoing tasks...".
  - [ ] **Action**: You CANNOT proceed until the task is finished.

## 6. General Polish
- [ ] **Timeline**: Check that tasks crossing midnight appear correctly in the timeline (Duration ~2h).
- [ ] **Total Hours**: Verify the operation total hours sum up correctly including cross-day tasks.
