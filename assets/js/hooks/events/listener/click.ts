export function click(event: MouseEvent) {
  const target = event.target as HTMLElement;
  const item = target.closest(".item");

  if (item) {
    item.classList.toggle("collapsed");
  }
}
