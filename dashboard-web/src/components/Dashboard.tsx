import { useEffect, useState } from 'react';
import { api } from '../services/api';
import { PowerGraph } from './PowerGraph';
import { HistoryTable } from './HistoryTable';
import { EnergyLatencyScatter } from './EnergyLatencyScatter';
import { AblationChart } from './AblationChart';
import { Zap, BarChart3, History, Activity } from 'lucide-react';

type TabType = 'realtime' | 'analysis' | 'ablation' | 'history';

export function Dashboard() {
    const [history, setHistory] = useState([]);
    const [latestTrace, setLatestTrace] = useState<any>(null);
    const [backend, setBackend] = useState('gpu');
    const [activeTab, setActiveTab] = useState<TabType>('realtime');

    // Poll for data
    useEffect(() => {
        // Clear trace when switching backends to prevent flickering
        setLatestTrace(null);

        const fetchData = async () => {
            try {
                const h = await api.getHistory();
                setHistory(h.runs || []);

                const t = await api.getLatestTrace(backend);
                if (t.runs && t.runs.length > 0) {
                    setLatestTrace(t.runs[0]);
                }
            } catch (e) {
                console.error("Failed to fetch data", e);
            }
        };

        fetchData();
        const interval = setInterval(fetchData, 1000); // 1s polling
        return () => clearInterval(interval);
    }, [backend]);

    const tabs = [
        { id: 'realtime' as TabType, label: 'Real-time', icon: Activity },
        { id: 'analysis' as TabType, label: 'Analysis', icon: BarChart3 },
        { id: 'ablation' as TabType, label: 'Ablation Studies', icon: BarChart3 },
        { id: 'history' as TabType, label: 'History', icon: History },
    ];

    return (
        <div className="min-h-screen bg-background p-8 font-sans text-foreground">
            <header className="mb-8 flex justify-between items-center">
                <div>
                    <h1 className="text-3xl font-bold flex items-center gap-3">
                        <Zap className="w-8 h-8 text-yellow-400 fill-yellow-400" />
                        Energy-Aware Inference
                    </h1>
                    <p className="text-muted-foreground mt-1">Real-time Power & Efficiency Monitoring</p>
                </div>
                <div className="flex gap-2">
                    <button
                        onClick={() => setBackend('gpu')}
                        className={`px-4 py-2 rounded font-bold transition-colors ${backend === 'gpu' ? 'bg-green-600 text-white' : 'bg-muted text-muted-foreground'}`}
                    >
                        GPU View
                    </button>
                    <button
                        onClick={() => setBackend('cpu')}
                        className={`px-4 py-2 rounded font-bold transition-colors ${backend === 'cpu' ? 'bg-orange-600 text-white' : 'bg-muted text-muted-foreground'}`}
                    >
                        CPU View
                    </button>
                </div>
            </header>

            {/* Tab Navigation */}
            <div className="flex gap-2 mb-6 border-b border-border">
                {tabs.map(tab => {
                    const Icon = tab.icon;
                    return (
                        <button
                            key={tab.id}
                            onClick={() => setActiveTab(tab.id)}
                            className={`flex items-center gap-2 px-4 py-3 font-semibold transition-colors border-b-2 ${activeTab === tab.id
                                    ? 'border-primary text-primary'
                                    : 'border-transparent text-muted-foreground hover:text-foreground'
                                }`}
                        >
                            <Icon className="w-4 h-4" />
                            {tab.label}
                        </button>
                    );
                })}
            </div>

            {/* Tab Content */}
            {activeTab === 'realtime' && (
                <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 h-[400px]">
                    <div className="lg:col-span-2 h-full">
                        {latestTrace ? (
                            <PowerGraph key={`${backend}-${latestTrace.run_id}`} data={latestTrace.power_trace} backend={backend} />
                        ) : (
                            <div className="h-full bg-card border rounded-lg flex items-center justify-center text-muted-foreground">
                                Waiting for data...
                            </div>
                        )}
                    </div>
                    <div className="bg-card border rounded-lg p-6 flex flex-col justify-center">
                        <h3 className="text-xl font-bold mb-4">Latest Run Stats</h3>
                        {latestTrace ? (
                            <div className="space-y-4">
                                <div className="flex justify-between border-b border-border pb-2">
                                    <span className="text-muted-foreground">Latency</span>
                                    <span className="font-mono text-xl">{Math.round(latestTrace.latency_ms)} ms</span>
                                </div>
                                <div className="flex justify-between border-b border-border pb-2">
                                    <span className="text-muted-foreground">Energy</span>
                                    <span className="font-mono text-xl text-yellow-400">{Math.round(latestTrace.energy_joules)} J</span>
                                </div>
                                <div className="flex justify-between pt-2">
                                    <span className="text-muted-foreground">Efficiency (EDP)</span>
                                    <span className="font-mono text-2xl text-blue-400">{(latestTrace.latency_ms * latestTrace.energy_joules / 1000).toFixed(1)} k</span>
                                </div>
                            </div>
                        ) : (
                            <p className="text-center text-muted-foreground">No run data available</p>
                        )}
                    </div>
                </div>
            )}

            {activeTab === 'analysis' && (
                <div className="space-y-6">
                    <EnergyLatencyScatter runs={history} />
                </div>
            )}

            {activeTab === 'ablation' && (
                <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
                    <AblationChart runs={history} type="threads" />
                    <AblationChart runs={history} type="layers" />
                    <div className="lg:col-span-2">
                        <AblationChart runs={history} type="batch" />
                    </div>
                </div>
            )}

            {activeTab === 'history' && (
                <HistoryTable runs={history} />
            )}
        </div>
    );
}
