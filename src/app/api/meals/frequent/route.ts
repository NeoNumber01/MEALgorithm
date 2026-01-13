import { NextResponse } from 'next/server'
import { getFrequentMeals } from '@/lib/meals/actions'

export async function GET() {
    const result = await getFrequentMeals(6)

    if ('error' in result) {
        return NextResponse.json({ error: result.error }, { status: 401 })
    }

    return NextResponse.json({ meals: result.meals || [] })
}
