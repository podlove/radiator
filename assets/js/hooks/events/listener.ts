import { CollapseParams } from "../types";
import { getNodeById } from "../node";

let watchdog;
const watchdogInterval = 400;

export function input(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;

  const uuid = target.getAttribute("data-uuid");
  const content = target.innerHTML;

  clearTimeout(watchdog);
  watchdog = setTimeout(() => {
    this.pushEventTo(this.el.phxHookId, "save", { uuid, content });
  }, watchdogInterval);
}

export function keydown(event: KeyboardEvent) {
  const target = event.target as HTMLDivElement;
  const uuid = target.getAttribute("data-uuid");

  if (event.key == "Tab") {
    event.preventDefault();

    if (event.shiftKey) {
      this.pushEventTo(this.el.phxHookId, "outdent", { uuid });
    } else {
      this.pushEventTo(this.el.phxHookId, "indent", { uuid });
    }
  }

  if (event.key === "Enter" && !event.shiftKey) {
    event.preventDefault();

    const selection = window.getSelection();
    const range = selection?.getRangeAt(0);
    const start = range!.startOffset;
    const end = range!.endOffset;

    const content = target.innerHTML;

    this.pushEventTo(this.el.phxHookId, "new", {
      uuid,
      content,
      selection: { start, end },
    });
  }
}

export function toggleCollapse({ detail: { uuid } }: CollapseParams) {
  const node = getNodeById(uuid);
  node!.toggleAttribute("data-collapsed");

  const collapsedStatus = localStorage.getItem(this.el.id) || "{}";
  const collapsed = JSON.parse(collapsedStatus);

  collapsed[uuid] = !collapsed[uuid];
  localStorage.setItem(this.el.id, JSON.stringify(collapsed));
}
