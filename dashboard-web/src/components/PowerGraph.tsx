import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export function PowerGraph({ data, backend }: { data: number[], backend: string }) {
    const chartData = data.map((val, idx) => ({ time: idx, power: val }));
    const color = backend === 'gpu' ? '#10b981' : '#f97316'; // Green vs Orange

    return (
        <div className="w-full h-full bg-card border rounded-lg p-4 flex flex-col">
            <h3 className="text-lg font-semibold mb-4 text-foreground">Real-time Power Draw ({backend.toUpperCase()})</h3>
            <div className="flex-1 min-h-0">
                <ResponsiveContainer width="100%" height="100%">
                    <LineChart data={chartData}>
                        <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                        <XAxis dataKey="time" hide />
                        <YAxis domain={[0, 'auto']} stroke="#94a3b8" />
                        <Tooltip
                            contentStyle={{ backgroundColor: '#334155', border: '1px solid #475569', borderRadius: '6px', color: '#f1f5f9' }}
                            itemStyle={{ color: '#fbbf24' }}
                            labelStyle={{ color: '#e2e8f0' }}
                        />
                        <Line
                            type="monotone"
                            dataKey="power"
                            stroke={color}
                            strokeWidth={2}
                            dot={false}
                            isAnimationActive={false}
                        />
                    </LineChart>
                </ResponsiveContainer>
            </div>
        </div>
    );
}
