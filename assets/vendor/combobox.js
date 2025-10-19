let Combobox = {
  mounted() {
    this.initElements();

    this.boundHandleScroll = this.updateDropdownPosition.bind(this);
    this.boundHandleKeyDown = this.handleKeyDown.bind(this);
    this.boundHandleDocumentClick = this.handleDocumentClick.bind(this);
    this.boundOpenButtonClick = this.handleOpenButtonClick.bind(this);
    this.boundOptionClickHandlers = [];
    this.boundClearButtonClick = this.handleClearButtonClick.bind(this);

    this.lastNavigatedValue = null;
    this.originalParent = null;
    this.isPortalActive = false;

    if (!this.openButton.id) {
      this.openButton.id = `combobox-trigger-${Math.random()
        .toString(36)
        .substring(2, 9)}`;
    }

    this.openButton.addEventListener("click", this.boundOpenButtonClick);
    this.openButton.addEventListener("keydown", this.boundHandleKeyDown);
    document.addEventListener("keydown", this.boundHandleKeyDown);

    this.setupOptionListeners();

    if (this.searchInput) {
      this.boundSearchInputHandler = this.handleSearch.bind(this);
      this.searchInput.addEventListener("input", this.boundSearchInputHandler);
      this.searchInput.addEventListener("keydown", this.boundHandleKeyDown);
    }

    if (this.clearButton) {
      this.clearButton.addEventListener("click", this.boundClearButtonClick);
    }

    document.addEventListener("click", this.boundHandleDocumentClick, true);

    this.observer = new MutationObserver(() => {
      this.syncDisplayFromSelect();
    });
    this.observer.observe(this.select, {
      attributes: true,
      childList: true,
      subtree: true,
    });

    this.syncDisplayFromSelect();
  },

  initElements() {
    this.select = this.el.querySelector(".combo-select");
    this.dropdown = this.el.querySelector('[data-part="listbox"]');
    this.openButton = this.el.querySelector(".combobox-trigger");
    this.selectedDisplay = this.el.querySelector(".selected-value");
    this.searchInput = this.el.querySelector(".combobox-search-input");
    this.clearButton = this.el.querySelector(
      '[data-part="clear-combobox-button"]',
    );
    this.dropdownOptions = this.getDropdownOptions();
  },

  getDropdownOptions() {
    if (this.isPortalActive && this.portalContainer) {
      return this.portalContainer.querySelectorAll(".combobox-option");
    }
    return this.el.querySelectorAll(".combobox-option");
  },

  setupOptionListeners() {
    this.boundOptionClickHandlers.forEach(({ btn, handler }) => {
      btn.removeEventListener("click", handler);
    });
    this.boundOptionClickHandlers = [];

    this.getDropdownOptions().forEach((btn) => {
      const handler = this.handleOptionClick.bind(this);
      btn.addEventListener("click", handler);
      this.boundOptionClickHandlers.push({ btn, handler });
    });
  },

  createPortalIfNeeded() {
    if (!this.portalContainer) {
      this.portalContainer = document.createElement("div");
      this.portalContainer.id = `combobox-portal-${this.openButton.id}`;
      this.portalContainer.style.cssText = `
        position: fixed;
        top: 0;
        left: 0;
        z-index: 9999;
        pointer-events: none;
      `;
      document.body.appendChild(this.portalContainer);
    }
  },

  moveDropdownToPortal() {
    if (!this.isPortalActive && this.dropdown) {
      this.createPortalIfNeeded();
      this.originalParent = this.dropdown.parentNode;

      const rect = this.openButton.getBoundingClientRect();
      const dropdownHeight = this.dropdown.offsetHeight || 200;
      const windowHeight = window.innerHeight;
      const spaceBelow = windowHeight - rect.bottom;
      const shouldShowAbove =
        spaceBelow < dropdownHeight && rect.top > dropdownHeight;

      this.portalContainer.appendChild(this.dropdown);
      this.portalContainer.style.pointerEvents = "auto";
      this.isPortalActive = true;

      this.setupOptionListeners();

      this.dropdown.style.position = "absolute";
      this.dropdown.style.top = shouldShowAbove
        ? `${rect.top - dropdownHeight - 8}px`
        : `${rect.bottom + 8}px`;
      this.dropdown.style.left = `${rect.left}px`;
      this.dropdown.style.width = `${rect.width}px`;

      this.dropdown.classList.remove("top-full", "mt-2", "bottom-full", "mb-2");
    }
  },

  moveDropdownBack() {
    if (this.isPortalActive && this.dropdown && this.originalParent) {
      this.originalParent.appendChild(this.dropdown);
      this.isPortalActive = false;
      if (this.portalContainer) {
        this.portalContainer.style.pointerEvents = "none";
      }

      this.setupOptionListeners();

      this.dropdown.style.position = "";
      this.dropdown.style.top = "";
      this.dropdown.style.left = "";
    }
  },

  checkForOverflowHidden() {
    let element = this.el.parentElement;
    while (element && element !== document.body) {
      const computedStyle = window.getComputedStyle(element);
      if (
        computedStyle.overflow === "hidden" ||
        computedStyle.overflowX === "hidden" ||
        computedStyle.overflowY === "hidden"
      ) {
        return true;
      }
      element = element.parentElement;
    }
    return false;
  },

  handleOpenButtonClick(e) {
    e.preventDefault();
    e.stopPropagation();
    if (this.dropdown.hasAttribute("hidden")) {
      this.openDropdown();
    } else {
      this.closeDropdown();
    }
  },

  openDropdown() {
    const hasOverflowHidden = this.checkForOverflowHidden();
    if (hasOverflowHidden) {
      this.moveDropdownToPortal();
    }

    this.dropdown.removeAttribute("hidden");
    this.openButton.setAttribute("aria-expanded", "true");

    requestAnimationFrame(() => {
      this.updateDropdownPosition();

      this.dropdownOptions = this.getDropdownOptions();

      let navigateTarget = null;
      if (this.lastNavigatedValue) {
        navigateTarget = Array.from(this.dropdownOptions).find(
          (opt) => opt.dataset.comboboxValue === this.lastNavigatedValue,
        );
      }
      if (!navigateTarget) {
        navigateTarget = Array.from(this.dropdownOptions).find((opt) =>
          opt.hasAttribute("data-combobox-selected"),
        );
      }

      if (!navigateTarget) {
        const visibleOptions = Array.from(this.dropdownOptions).filter(
          (opt) => opt.style.display !== "none",
        );
        if (visibleOptions.length > 0) {
          navigateTarget = visibleOptions[0];
        }
      }

      Array.from(this.dropdownOptions).forEach((opt) =>
        opt.removeAttribute("data-combobox-navigate"),
      );

      if (navigateTarget) {
        this.navigateToOption(navigateTarget);
      } else {
        this.openButton.removeAttribute("aria-activedescendant");
      }

      if (this.searchInput) {
        this.searchInput.focus();
      } else {
        this.openButton.focus();
      }
    });

    window.addEventListener("scroll", this.boundHandleScroll, {
      passive: true,
    });
  },

  closeDropdown() {
    if (!this.dropdown.hasAttribute("hidden")) {
      this.dropdown.setAttribute("hidden", true);
    }
    this.openButton.setAttribute("aria-expanded", "false");
    this.openButton.removeAttribute("aria-activedescendant");
    window.removeEventListener("scroll", this.boundHandleScroll);
    document.removeEventListener("keydown", this.boundHandleKeyDown);

    this.moveDropdownBack();
  },

  navigateToOption(option) {
    if (!option) return;

    Array.from(this.getDropdownOptions()).forEach((opt) => {
      opt.removeAttribute("data-combobox-navigate");
    });

    option.setAttribute("data-combobox-navigate", "");
    option.scrollIntoView({ block: "nearest" });
    this.lastNavigatedValue = option.dataset.comboboxValue;

    if (option.id) {
      this.openButton.setAttribute("aria-activedescendant", option.id);
    } else {
      this.openButton.removeAttribute("aria-activedescendant");
    }
  },

  resetNavigateToFirstOption() {
    const visibleOptions = Array.from(this.getDropdownOptions()).filter(
      (opt) => opt.style.display !== "none",
    );

    if (visibleOptions.length > 0) {
      this.navigateToOption(visibleOptions[0]);
    }
  },

  updateDropdownPosition() {
    const rect = this.openButton.getBoundingClientRect();
    const dropdownHeight = this.dropdown.offsetHeight || 200;
    const windowHeight = window.innerHeight;
    const spaceBelow = windowHeight - rect.bottom;

    if (this.isPortalActive) {
      const shouldShowAbove =
        spaceBelow < dropdownHeight && rect.top > dropdownHeight;

      if (shouldShowAbove) {
        this.dropdown.style.top = `${rect.top - dropdownHeight - 8}px`;
      } else {
        this.dropdown.style.top = `${rect.bottom + 8}px`;
      }

      this.dropdown.style.left = `${rect.left}px`;
      this.dropdown.style.width = `${rect.width}px`;

      this.dropdown.classList.remove("top-full", "mt-2", "bottom-full", "mb-2");
    } else {
      if (spaceBelow < dropdownHeight) {
        this.dropdown.classList.remove("top-full", "mt-2");
        this.dropdown.classList.add("bottom-full", "mb-2");
      } else {
        this.dropdown.classList.remove("bottom-full", "mb-2");
        this.dropdown.classList.add("top-full", "mt-2");
      }
    }
  },

  handleSearch(e) {
    const query = e.target.value.toLowerCase();
    this.dropdownOptions = this.getDropdownOptions();

    Array.from(this.dropdownOptions).forEach((option) => {
      const valueAttr = option
        .getAttribute("data-combobox-value")
        .toLowerCase();
      const displayText = option.textContent.trim().toLowerCase();
      const matches = valueAttr.includes(query) || displayText.includes(query);
      option.style.display = matches ? "" : "none";
    });

    const noResults = this.dropdown.querySelector(".no-results");
    const visibleOptions = Array.from(this.dropdownOptions).filter(
      (option) => option.style.display !== "none",
    );
    if (visibleOptions.length === 0) {
      if (noResults) noResults.classList.remove("hidden");
    } else {
      if (noResults) noResults.classList.add("hidden");
    }

    const optionGroups = this.dropdown.querySelectorAll(".option-group");
    optionGroups.forEach((group) => {
      const visibleInGroup = group.querySelectorAll(
        '.combobox-option:not([style*="display: none"])',
      );
      group.style.display = visibleInGroup.length === 0 ? "none" : "";
    });

    this.resetNavigateToFirstOption();
  },

  handleOptionClick(e) {
    e.preventDefault();
    const optionEl = e.target.closest(".combobox-option");
    const value = optionEl.dataset.comboboxValue;
    const isMultiple = this.select.multiple;

    this.lastNavigatedValue = value;

    if (isMultiple) {
      this.toggleOption(value, optionEl);
      this.updateMultipleSelectedDisplay();
      this.dispatchChangeEvent();
      if (this.searchInput) {
        setTimeout(() => {
          this.searchInput.focus();
        }, 0);
      }
    } else {
      Array.from(this.getDropdownOptions()).forEach((opt) => {
        opt.removeAttribute("data-combobox-selected");
        opt.setAttribute("aria-selected", "false");
      });
      this.selectSingleOption(value);
      optionEl.setAttribute("data-combobox-selected", "");
      optionEl.setAttribute("aria-selected", "true");
      this.closeDropdown();
      this.openButton.focus();
    }
  },

  toggleOption(value, optionEl) {
    const option = Array.from(this.select.options).find(
      (opt) => opt.value === value,
    );
    if (option) {
      option.selected = !option.selected;
      if (option.selected) {
        option.setAttribute("selected", "");
        optionEl.setAttribute("data-combobox-selected", "");
        optionEl.setAttribute("aria-selected", "true");
      } else {
        option.removeAttribute("selected");
        optionEl.removeAttribute("data-combobox-selected");
        optionEl.setAttribute("aria-selected", "false");
      }
    }
  },

  selectSingleOption(value) {
    Array.from(this.select.options).forEach((opt) => {
      opt.selected = opt.value === value;
    });
    this.updateSingleSelectedDisplay();
    this.dispatchChangeEvent();
  },

  updateSingleSelectedDisplay() {
    Array.from(this.getDropdownOptions()).forEach((opt) => {
      opt.removeAttribute("data-combobox-selected");
      opt.setAttribute("aria-selected", "false");
    });

    const selectedOption = Array.from(this.select.options).find(
      (opt) => opt.selected && opt.value !== "",
    );
    const placeholder = this.el.querySelector(".combobox-placeholder");
    const clearBtn = this.el.querySelector(
      '[data-part="clear-combobox-button"]',
    );

    if (selectedOption) {
      if (placeholder) placeholder.style.display = "none";
      const renderedOption = Array.from(this.getDropdownOptions()).find(
        (opt) => opt.dataset.comboboxValue === selectedOption.value,
      );
      this.selectedDisplay.innerHTML = renderedOption
        ? renderedOption.innerHTML
        : selectedOption.textContent;
      if (renderedOption) {
        renderedOption.setAttribute("data-combobox-selected", "");
        renderedOption.setAttribute("aria-selected", "true");
      }
      if (clearBtn) clearBtn.hidden = false;
    } else {
      if (placeholder) placeholder.style.display = "";
      this.selectedDisplay.textContent = "";
      if (clearBtn) clearBtn.hidden = true;
      this.lastNavigatedValue = null;
    }
  },

  updateMultipleSelectedDisplay() {
    this.selectedDisplay.innerHTML = "";
    const selectedOptions = Array.from(this.select.options).filter(
      (opt) => opt.selected,
    );
    const placeholder = this.el.querySelector(".combobox-placeholder");
    const clearBtn = this.el.querySelector(
      '[data-part="clear-combobox-button"]',
    );

    if (selectedOptions.length > 0) {
      placeholder.style.display = "none";
      if (clearBtn) clearBtn.hidden = false;
    } else {
      placeholder.style.display = "";
      if (clearBtn) clearBtn.hidden = true;
    }

    selectedOptions.forEach((option) => {
      const optionEl = Array.from(this.getDropdownOptions()).find(
        (opt) => opt.dataset.comboboxValue === option.value,
      );
      if (optionEl) {
        optionEl.setAttribute("data-combobox-selected", "");
        optionEl.setAttribute("aria-selected", "true");
      }
    });

    selectedOptions.forEach((option) => {
      const pill = document.createElement("span");
      pill.classList.add(
        "selected-item",
        "flex",
        "items-center",
        "gap-2",
        "combobox-pill",
      );

      const renderedOption = Array.from(this.getDropdownOptions()).find(
        (opt) => opt.dataset.comboboxValue === option.value,
      );
      if (renderedOption) {
        pill.innerHTML = renderedOption.innerHTML;
      } else {
        pill.textContent = option.textContent;
      }

      const closeBtn = document.createElement("span");
      closeBtn.innerHTML =
        '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="combobox-icon"><path d="M18 6 6 18"/><path d="m6 6 12 12"/></svg>';
      closeBtn.addEventListener("click", (e) => {
        e.preventDefault();
        e.stopPropagation();
        option.selected = false;
        option.removeAttribute("selected");
        const optionEl = Array.from(this.getDropdownOptions()).find(
          (opt) => opt.dataset.comboboxValue === option.value,
        );
        if (optionEl) {
          optionEl.removeAttribute("data-combobox-selected");
          optionEl.setAttribute("aria-selected", "false");
        }
        this.updateMultipleSelectedDisplay();
        this.dispatchChangeEvent();
      });
      pill.appendChild(closeBtn);
      this.selectedDisplay.appendChild(pill);
    });
  },

  handleKeyDown(e) {
    const key = e.key;

    if (
      this.dropdown.hasAttribute("hidden") &&
      document.activeElement === this.openButton
    ) {
      if (key === " " || key === "Enter") {
        e.preventDefault();
        this.openDropdown();
        return;
      }
      return;
    }

    if (this.dropdown.hasAttribute("hidden")) return;

    if (key === "Escape") {
      this.closeDropdown();
      this.openButton.focus();
      return;
    }

    const isNavigationKey = [
      "ArrowDown",
      "ArrowUp",
      "Enter",
      "Tab",
      "Escape",
    ].includes(key);

    if (
      this.searchInput &&
      document.activeElement === this.searchInput &&
      !isNavigationKey &&
      key.length === 1
    ) {
      return;
    }

    const visibleOptions = Array.from(this.getDropdownOptions()).filter(
      (opt) => opt.style.display !== "none",
    );

    if (visibleOptions.length === 0) return;

    let currentIndex = visibleOptions.findIndex((opt) =>
      opt.hasAttribute("data-combobox-navigate"),
    );

    if (key === "ArrowDown") {
      e.preventDefault();
      e.stopPropagation();
      currentIndex =
        currentIndex < 0 ? 0 : (currentIndex + 1) % visibleOptions.length;
      this.navigateToOption(visibleOptions[currentIndex]);
      return;
    } else if (key === "ArrowUp") {
      e.preventDefault();
      e.stopPropagation();
      currentIndex =
        currentIndex < 0
          ? visibleOptions.length - 1
          : (currentIndex - 1 + visibleOptions.length) % visibleOptions.length;
      this.navigateToOption(visibleOptions[currentIndex]);
      return;
    } else if (key === "Enter") {
      e.preventDefault();
      e.stopPropagation();
      if (currentIndex >= 0) {
        const targetOption = visibleOptions[currentIndex];
        const value = targetOption.dataset.comboboxValue;
        this.lastNavigatedValue = value;

        if (this.select.multiple) {
          this.toggleOption(value, targetOption);
          this.updateMultipleSelectedDisplay();
          this.dispatchChangeEvent();
          this.navigateToOption(targetOption);
        } else {
          Array.from(this.getDropdownOptions()).forEach((opt) => {
            opt.removeAttribute("data-combobox-selected");
            opt.setAttribute("aria-selected", "false");
          });
          this.selectSingleOption(value);
          targetOption.setAttribute("data-combobox-selected", "");
          targetOption.setAttribute("aria-selected", "true");
          this.closeDropdown();
          this.openButton.focus();
        }
      }
      return;
    } else if (key === "Tab") {
      this.closeDropdown();
      return;
    } else if (key.length === 1) {
      e.preventDefault();
      this.handleCharacterNavigation(key.toLowerCase(), visibleOptions);
      return;
    } else {
      return;
    }
  },

  handleCharacterNavigation(char, options) {
    const matchingOptions = options.filter((opt) => {
      const valueAttr = opt.getAttribute("data-combobox-value") || "";
      const labelText = opt.textContent.trim().toLowerCase();
      return (
        valueAttr.toLowerCase().startsWith(char) || labelText.startsWith(char)
      );
    });
    if (matchingOptions.length === 0) return;

    let currentIndex = matchingOptions.findIndex((opt) =>
      opt.hasAttribute("data-combobox-navigate"),
    );
    currentIndex = (currentIndex + 1) % matchingOptions.length;

    this.navigateToOption(matchingOptions[currentIndex]);
  },

  syncDisplayFromSelect() {
    Array.from(this.getDropdownOptions()).forEach((opt) => {
      opt.removeAttribute("data-combobox-selected");
      opt.setAttribute("aria-selected", "false");
    });

    if (this.select.multiple) {
      this.updateMultipleSelectedDisplay();
    } else {
      this.updateSingleSelectedDisplay();
    }
  },

  handleDocumentClick(e) {
    if (
      !this.el.contains(e.target) &&
      !(
        this.isPortalActive &&
        this.portalContainer &&
        this.portalContainer.contains(e.target)
      ) &&
      !this.isClickOnScrollbar(e)
    ) {
      this.closeDropdown();
    }
  },

  isClickOnScrollbar(e) {
    return (
      e.clientX >= document.documentElement.clientWidth ||
      e.clientY >= document.documentElement.clientHeight
    );
  },

  dispatchChangeEvent() {
    const changeEvent = new Event("change", { bubbles: true });
    this.select.dispatchEvent(changeEvent);
  },

  handleClearButtonClick(e) {
    e.preventDefault();
    e.stopPropagation();
    Array.from(this.select.options).forEach((opt) => {
      opt.selected = false;
      opt.removeAttribute("selected");
    });
    Array.from(this.getDropdownOptions()).forEach((opt) => {
      opt.removeAttribute("data-combobox-selected");
      opt.setAttribute("aria-selected", "false");
    });
    this.syncDisplayFromSelect();
    this.closeDropdown();
    this.dispatchChangeEvent();
    this.resetNavigateToFirstOption();
  },

  destroyed() {
    this.closeDropdown();

    if (this.portalContainer && this.portalContainer.parentNode) {
      this.portalContainer.parentNode.removeChild(this.portalContainer);
    }

    if (this.observer) {
      this.observer.disconnect();
    }
    document.removeEventListener("click", this.boundHandleDocumentClick, true);
    if (this.openButton && this.boundOpenButtonClick) {
      this.openButton.removeEventListener("click", this.boundOpenButtonClick);
      this.openButton.removeEventListener("keydown", this.boundHandleKeyDown);
    }
    if (
      this.boundOptionClickHandlers &&
      this.boundOptionClickHandlers.length > 0
    ) {
      this.boundOptionClickHandlers.forEach(({ btn, handler }) => {
        btn.removeEventListener("click", handler);
      });
    }
    if (this.searchInput && this.boundSearchInputHandler) {
      this.searchInput.removeEventListener(
        "input",
        this.boundSearchInputHandler,
      );
      this.searchInput.removeEventListener("keydown", this.boundHandleKeyDown);
    }
    if (this.clearButton && this.boundClearButtonClick) {
      this.clearButton.removeEventListener("click", this.boundClearButtonClick);
    }
  },
};

export default Combobox;
