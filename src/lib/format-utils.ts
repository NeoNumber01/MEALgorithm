/**
 * Utility functions for formatting numbers in the UI
 */

/**
 * Format a number to display with at most 1 decimal place
 * - If the number is an integer, display without decimals
 * - If the number has a fractional part, round to 1 decimal
 * 
 * @param value - The number to format
 * @returns Formatted string representation
 */
export function formatNumber(value: number | undefined | null): string {
    if (value === undefined || value === null || isNaN(value)) {
        return '0'
    }

    // Round to 1 decimal place
    const rounded = Math.round(value * 10) / 10

    // If it's a whole number, display without decimals
    if (Number.isInteger(rounded)) {
        return rounded.toString()
    }

    // Display with 1 decimal place
    return rounded.toFixed(1)
}

/**
 * Format a number with locale string and at most 1 decimal place
 * Good for larger numbers that benefit from thousand separators
 * 
 * @param value - The number to format
 * @returns Formatted string with locale separators
 */
export function formatNumberLocale(value: number | undefined | null): string {
    if (value === undefined || value === null || isNaN(value)) {
        return '0'
    }

    // Round to 1 decimal place
    const rounded = Math.round(value * 10) / 10

    return rounded.toLocaleString('en-US', {
        minimumFractionDigits: 0,
        maximumFractionDigits: 1
    })
}
