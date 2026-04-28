'use client'

import { useMemo } from 'react'
import {
  LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, ReferenceLine,
} from 'recharts'
import { formatShortDate } from '@/lib/utils/date'
import { VITAL_COLORS, VITAL_UNITS } from '@/lib/types'
import type { Vital, VitalType } from '@/lib/types'

interface VitalsChartProps {
  vitals: Vital[]
  type: VitalType
}

interface ChartDataPoint {
  date: string
  value: number
  systolic?: number
  diastolic?: number
}

const REFERENCE_LINES: Partial<Record<VitalType, { value: number; label: string; color: string }[]>> = {
  temperature: [
    { value: 37.5, label: 'Fièvre', color: '#E53E3E' },
    { value: 36.0, label: 'Hypothermie', color: '#3182CE' },
  ],
  glucose: [
    { value: 1.1, label: 'Max', color: '#E53E3E' },
    { value: 0.7, label: 'Min', color: '#3182CE' },
  ],
}

function parseBloodPressure(value: string): { systolic: number; diastolic: number } | null {
  const match = value.match(/(\d+)\s*\/\s*(\d+)/)
  if (!match) return null
  return { systolic: parseInt(match[1]), diastolic: parseInt(match[2]) }
}

export function VitalsChart({ vitals, type }: VitalsChartProps) {
  const color = VITAL_COLORS[type]
  const unit = VITAL_UNITS[type]

  const data = useMemo((): ChartDataPoint[] => {
    return [...vitals]
      .sort((a, b) => new Date(a.measured_at).getTime() - new Date(b.measured_at).getTime())
      .map((v) => {
        if (type === 'blood_pressure') {
          const bp = parseBloodPressure(v.value)
          return {
            date: formatShortDate(v.measured_at),
            value: bp?.systolic ?? 0,
            systolic: bp?.systolic,
            diastolic: bp?.diastolic,
          }
        }
        return {
          date: formatShortDate(v.measured_at),
          value: parseFloat(v.value) || 0,
        }
      })
  }, [vitals, type])

  if (data.length === 0) return null

  const refs = REFERENCE_LINES[type] || []

  return (
    <ResponsiveContainer width="100%" height={200}>
      <LineChart data={data} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="hsl(var(--border))" />
        <XAxis
          dataKey="date"
          tick={{ fontSize: 11, fill: 'hsl(var(--muted-foreground))' }}
          tickLine={false}
          axisLine={false}
        />
        <YAxis
          tick={{ fontSize: 11, fill: 'hsl(var(--muted-foreground))' }}
          tickLine={false}
          axisLine={false}
          tickFormatter={(v) => `${v}`}
        />
        <Tooltip
          contentStyle={{
            background: 'hsl(var(--card))',
            border: '1px solid hsl(var(--border))',
            borderRadius: '12px',
            fontSize: '12px',
          }}
          formatter={(value: number, name: string) => {
            if (name === 'systolic') return [`${value} ${unit}`, 'Systolique']
            if (name === 'diastolic') return [`${value} mmHg`, 'Diastolique']
            return [`${value} ${unit}`, 'Valeur']
          }}
        />
        {refs.map((r) => (
          <ReferenceLine key={r.label} y={r.value} stroke={r.color} strokeDasharray="4 4" label={{ value: r.label, fontSize: 10 }} />
        ))}
        {type === 'blood_pressure' ? (
          <>
            <Line type="monotone" dataKey="systolic" stroke={color} strokeWidth={2} dot={{ r: 3, fill: color }} name="systolic" />
            <Line type="monotone" dataKey="diastolic" stroke="#805AD5" strokeWidth={2} dot={{ r: 3, fill: '#805AD5' }} name="diastolic" strokeDasharray="4 4" />
          </>
        ) : (
          <Line type="monotone" dataKey="value" stroke={color} strokeWidth={2} dot={{ r: 3, fill: color }} name="value" />
        )}
      </LineChart>
    </ResponsiveContainer>
  )
}
