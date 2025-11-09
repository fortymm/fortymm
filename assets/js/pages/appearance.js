// Appearance settings page JavaScript

export function init() {
  const themeSelect = document.querySelector('#appearance-form select')

  if (themeSelect) {
    const currentTheme = localStorage.getItem('phx:theme') || 'system'

    // Map the current theme to dropdown value
    // If it's "system", use "system", otherwise use "light" (Single Theme option)
    const dropdownValue = currentTheme === 'system' ? 'system' : 'light'
    themeSelect.value = dropdownValue

    // Show appropriate panels based on dropdown value
    toggleThemePanels(dropdownValue)

    // Update selected theme in single theme panel
    if (currentTheme !== 'system') {
      const radioToCheck = document.querySelector(`input[name="theme-choice"][value="${currentTheme}"]`)
      if (radioToCheck) {
        radioToCheck.checked = true
      }
    }

    // Set up event listener for theme mode select
    themeSelect.addEventListener('change', (e) => {
      toggleThemePanels(e.target.value)
      selectTheme(e.target.value)
    })
  }

  // Set up event listeners for theme radio buttons
  const themeRadios = document.querySelectorAll('input[name="theme-choice"]')
  themeRadios.forEach(radio => {
    radio.addEventListener('change', (e) => {
      selectTheme(e.target.value)
    })
  })

  // Update active theme on page load
  updateActiveTheme()

  // Listen for system theme changes
  const darkModeQuery = window.matchMedia('(prefers-color-scheme: dark)')
  darkModeQuery.addEventListener('change', updateActiveTheme)
}

// Toggle between system and single theme panels
window.toggleThemePanels = function (dropdownValue) {
  const themePanels = document.getElementById('theme-panels')
  const singleThemePanel = document.getElementById('single-theme-panel')

  if (dropdownValue === 'system') {
    themePanels?.classList.remove('hidden')
    singleThemePanel?.classList.add('hidden')
  } else {
    themePanels?.classList.add('hidden')
    singleThemePanel?.classList.remove('hidden')
  }
}

// Select a theme and apply it
window.selectTheme = function (theme) {
  const evt = new CustomEvent('phx:set-theme', {
    detail: { theme: theme }
  })
  window.dispatchEvent(evt)

  // Update radio button selection
  const radioToCheck = document.querySelector(`input[name="theme-choice"][value="${theme}"]`)
  if (radioToCheck) {
    radioToCheck.checked = true
  }
}

// Update active theme indicator based on system preference
function updateActiveTheme() {
  const isDark = window.matchMedia('(prefers-color-scheme: dark)').matches
  const lightCard = document.getElementById('light-theme-card')
  const darkCard = document.getElementById('dark-theme-card')
  const lightBadge = document.getElementById('light-theme-badge')
  const darkBadge = document.getElementById('dark-theme-badge')

  if (isDark) {
    // Dark theme is active
    lightCard?.classList.remove('border-primary')
    lightCard?.classList.add('border-base-300')
    darkCard?.classList.add('border-primary')
    darkCard?.classList.remove('border-base-300')
    lightBadge?.classList.add('hidden')
    darkBadge?.classList.remove('hidden')
  } else {
    // Light theme is active
    lightCard?.classList.add('border-primary')
    lightCard?.classList.remove('border-base-300')
    darkCard?.classList.remove('border-primary')
    darkCard?.classList.add('border-base-300')
    lightBadge?.classList.remove('hidden')
    darkBadge?.classList.add('hidden')
  }
}
