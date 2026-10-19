/* Generic hybrid-course engine: mark-complete gating, resume, spaced review.
   Reads hybrid-course-data.json next to it, so any course built by
   build_course.py works without editing this file. */

const root = document.querySelector("#course-root");
const courseMeta = root.dataset;
const els = {
  label: document.querySelector("#progress-label"),
  bar: document.querySelector("#progress-bar"),
  lesson: document.querySelector("#lesson"),
  prev: document.querySelector("#previous-button"),
  next: document.querySelector("#next-button"),
  select: document.querySelector("#day-select"),
  complete: document.querySelector("#complete-button"),
  reset: document.querySelector("#reset-button"),
  status: document.querySelector("#completion-status"),
  message: document.querySelector("#storage-message"),
  resume: document.querySelector("#resume-banner"),
};

let spec = null;
let lessons = [];
let current = 1;
let storageOk = true;
let state = { completed: [], blanked: [], lastOpened: 1, version: 1 };

// The spine grows by inserting days in front of existing ones, so an old tick mark
// would otherwise land on a different lesson. The build records the old->new table in
// the curriculum, and stored progress is translated through it exactly once.
function migrate(saved) {
  if (saved.progressShift || !spec || !spec.course || !spec.course.day_shift) return saved;
  const map = spec.course.day_shift.map || {};
  const move = (n) => (Number.isInteger(n) && map[n] !== undefined ? map[n] : n);
  const shifted = {
    ...saved,
    completed: (Array.isArray(saved.completed) ? saved.completed : []).map(move),
    blanked: (Array.isArray(saved.blanked) ? saved.blanked : []).map(move),
    lastOpened: move(saved.lastOpened),
    progressShift: spec.course.day_shift.applied,
  };
  try {
    localStorage.setItem(storageKey(), JSON.stringify(shifted));
  } catch (error) {
    /* the translation still applies in memory for this visit */
  }
  return shifted;
}

function storageKey() {
  return spec ? spec.storageKey : `local-learning-lab.${courseMeta.courseId}.v1`;
}

function loadState() {
  try {
    const raw = localStorage.getItem(storageKey());
    if (!raw) return;
    const saved = migrate(JSON.parse(raw));
    const total = lessons.length || Number.MAX_SAFE_INTEGER;
    const ok = (n) => Number.isInteger(n) && n >= 1 && n <= total;
    state = {
      completed: Array.isArray(saved.completed) ? saved.completed.filter(ok) : [],
      blanked: Array.isArray(saved.blanked) ? saved.blanked.filter(ok) : [],
      lastOpened: ok(saved.lastOpened) ? saved.lastOpened : 1,
      version: 1,
    };
  } catch (error) {
    storageOk = false;
    say(`Progress could not be read (${error.message}). The course still works, but it may not persist.`);
  }
}

function saveState() {
  if (!storageOk) return;
  try {
    state.lastOpened = current;
    localStorage.setItem(storageKey(), JSON.stringify(state));
  } catch (error) {
    storageOk = false;
    say(`Progress could not be saved (${error.message}).`);
  }
}

function say(text) {
  els.message.textContent = text;
}

function doneSet() {
  return new Set(state.completed);
}

function firstIncomplete() {
  const done = doneSet();
  for (const lesson of lessons) {
    if (!done.has(lesson.day)) return lesson.day;
  }
  return lessons.length ? lessons[lessons.length - 1].day : 1;
}

function byDay(day) {
  return lessons.find((lesson) => lesson.day === day);
}

function escapeHtml(value) {
  return String(value ?? "").replace(/[&<>"']/g, (c) => ({
    "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;",
  }[c]));
}

/* Curriculum text is authored in Markdown-lite: `code` spans show as code and
   **bold** shows as bold. Nothing else from Markdown is supported, so curriculum
   fields stay plain prose and the escaping above still protects against injection. */
function md(value) {
  return escapeHtml(value)
    .replace(/\*\*([^*]+)\*\*/g, "<strong>$1</strong>")
    .replace(/`([^`]+)`/g, "<code>$1</code>");
}

function recallBlock(lesson) {
  const offsets = spec?.recallOffsets ?? [1, 3, 7, 21];
  const items = [];
  for (const offset of offsets) {
    const past = byDay(lesson.day - offset);
    if (past) items.push({ lesson: past, ago: offset });
  }
  const rows = items.map(({ lesson: past, ago }) => {
    const blanked = state.blanked.includes(past.day);
    return `<div class="recall-item${blanked ? " blanked" : ""}">
      <div>
        <strong>Day ${past.day}</strong>
        <span class="ago">${ago} lesson${ago === 1 ? "" : "s"} back</span>
        <p class="idea">${md(past.idea)}</p>
        <a href="${escapeHtml(past.href)}">open that page</a>
      </div>
      <div class="recall-answer">
        <button type="button" class="quiet tiny" data-recalled="${past.day}">I remembered it</button>
        <button type="button" class="quiet tiny warn" data-blanked="${past.day}">It went blank</button>
      </div>
    </div>`;
  }).join("");
  const queue = state.blanked.filter((day) => day !== lesson.day);
  const queueNote = queue.length
    ? `<p class="queue">Your retry queue: ${queue.map((d) => `Day ${d}`).join(", ")}. `
      + `Re-do those from memory before advancing — that is the part that stops the restart spiral.</p>`
    : "";
  return `<h3>1 · Recall first (${escapeHtml(lesson.track || "")})</h3>
    <p class="prompt">${md(lesson.recall || "Say the last idea from memory before you read anything.")}</p>
    ${rows ? `<details open><summary>Spaced review (${items.length} older ideas)</summary>${rows}</details>` : ""}
    ${queueNote}`;
}

function render() {
  const lesson = byDay(current) || lessons[0];
  if (!lesson) return;
  const done = doneSet();
  const total = lessons.length;
  const count = done.size;
  els.bar.max = total;
  els.bar.value = count;
  els.label.textContent = count === total
    ? `Course complete · all ${total} lessons marked`
    : `${count} of ${total} lessons complete · now on Day ${lesson.day}`;
  els.resume.textContent = done.size
    ? `Resume point: Day ${lesson.day} — ${lesson.title}. `
      + `${done.size} lesson${done.size === 1 ? "" : "s"} already yours.`
    : `Start here: Day ${lesson.day} — ${lesson.title}. Nothing marked complete yet.`;

  const source = lesson.source
    ? `<p class="source">Source: ${md(lesson.source)}</p>` : "";
  const bite = lesson.bite
    ? `<blockquote class="bite">${md(lesson.bite)}</blockquote>` : "";
  const practice = lesson.practice
    ? `<h3>3 · Practice</h3><p>${md(lesson.practice)}</p>` : "";
  const check = lesson.check ? `<h3>4 · Check</h3><p>${md(lesson.check)}</p>` : "";
  const gate = lesson.gate ? `<p class="gate"><strong>Mastery gate:</strong> ${md(lesson.gate)}</p>` : "";
  const link = lesson.href
    ? `<p><a href="${escapeHtml(lesson.href)}">Open the full lesson page (the extracted book text is there)</a></p>` : "";

  els.lesson.innerHTML = `<h2>Day ${lesson.day}: ${escapeHtml(lesson.title)}</h2>
    ${source}
    ${recallBlock(lesson)}
    <h3>2 · Read the author</h3>
    <p class="idea big">${md(lesson.idea || "")}</p>
    ${bite}${practice}${check}${gate}${link}`;

  const isDone = done.has(lesson.day);
  els.prev.disabled = lesson.day <= (lessons[0]?.day ?? 1);
  els.next.disabled = !isDone;
  els.complete.disabled = isDone;
  els.complete.textContent = isDone ? "Already complete" : "Mark this lesson complete";
  els.status.textContent = isDone ? "✓ marked complete" : "";
  els.select.value = String(lesson.day);
}

function wire() {
  els.complete.addEventListener("click", () => {
    if (!state.completed.includes(current)) state.completed.push(current);
    state.blanked = state.blanked.filter((day) => day !== current);
    const nextDay = firstIncomplete();
    if (nextDay !== current) current = nextDay;
    saveState();
    render();
  });
  els.next.addEventListener("click", () => {
    if (byDay(current + 1)) { current += 1; saveState(); render(); }
  });
  els.prev.addEventListener("click", () => {
    if (byDay(current - 1)) { current -= 1; saveState(); render(); }
  });
  els.select.addEventListener("change", (event) => {
    current = Number(event.target.value); saveState(); render();
  });
  els.reset.addEventListener("click", () => {
    if (!confirm("Clear completion and review state for this course? Book text and files are untouched.")) return;
    state = { completed: [], blanked: [], lastOpened: lessons[0]?.day ?? 1, version: 1 };
    saveState();
    current = lessons[0]?.day ?? 1;
    render();
  });
  els.lesson.addEventListener("click", (event) => {
    const recalled = event.target.dataset?.recalled;
    const blanked = event.target.dataset?.blanked;
    if (recalled) {
      state.blanked = state.blanked.filter((d) => d !== Number(recalled));
      saveState(); render();
    } else if (blanked) {
      const day = Number(blanked);
      if (!state.blanked.includes(day)) state.blanked.push(day);
      saveState(); render();
      say(`Day ${day} added to your retry queue. That is the system working, not failing.`);
    }
  });
}

async function boot() {
  try {
    const response = await fetch("hybrid-course-data.json", { cache: "no-store" });
    if (!response.ok) throw new Error(`HTTP ${response.status}`);
    spec = await response.json();
  } catch (error) {
    els.lesson.innerHTML = `<h2>This course needs the local portal</h2>
      <p>Open it through <code>http://127.0.0.1:8000/</code> after running
      <code>./exercises/serve-site.sh</code> from the <code>ex</code> folder.
      Opening the file directly blocks the curriculum from loading
      (${escapeHtml(error.message)}).</p>`;
    say("Course data unavailable offline from file://.");
    return;
  }
  lessons = spec.lessons;
  els.select.innerHTML = lessons.map((l) => `<option value="${l.day}">Day ${l.day}: ${escapeHtml(l.title)}</option>`).join("");
  loadState();
  // Resume: the last page you opened, unless you had already finished it.
  current = byDay(state.lastOpened) ? state.lastOpened : firstIncomplete();
  if (doneSet().has(current)) current = firstIncomplete();
  wire();
  render();
  say("Progress is saved in this browser on this device.");
}

boot();
