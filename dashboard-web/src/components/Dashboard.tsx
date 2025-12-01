import { useEffect, useState } from 'react';
import { api } from '../services/api';
import { PowerGraph } from './PowerGraph';
import { HistoryTable } from './HistoryTable';
import { EnergyLatencyScatter } from './EnergyLatencyScatter';
import { AblationChart } from './AblationChart';
import { ComparisonView } from './ComparisonView';
import { InfoTooltip } from './InfoTooltip';
import { LoadingSpinner, SkeletonCard } from './LoadingStates';
import { Zap, BarChart3, History, Activity } from 'lucide-react';

type TabType = 'realtime' | 'analysis' | 'ablation' | 'history';

export function Dashboard() {
    const [history, setHistory] = useState([]);
    const [latestTrace, setLatestTrace] = useState<any>(null);
    const [backend, setBackend] = useState('gpu');
    const [activeTab, setActiveTab] = useState<TabType>('realtime');
    const [isLoading, setIsLoading] = useState(true);
    const [selectedRuns, setSelectedRuns] = useState<string[]>([]);
    const [comparison, setComparison] = useState<any>(null);

    // Poll for data
    useEffect(() => {
        setLatestTrace(null);
        setIsLoading(true);

        const fetchData = async () => {
            try {
                const h = await api.getHistory();
                setHistory(h.runs || []);

                const t = await api.getLatestTrace(backend);
                if (t.runs && t.runs.length > 0) {
                    setLatestTrace(t.runs[0]);
                }
                setIsLoading(false);
            } catch (e) {
                console.error("Failed to fetch data", e);
                setIsLoading(false);
            }
        };

        fetchData();
        const interval = setInterval(fetchData, 1000);
        return () => clearInterval(interval);
    }, [backend]);

    const handleToggleSelection = (runId: string) => {
        setSelectedRuns(prev =>
            prev.includes(runId) ? prev.filter(id => id !== runId) : [...prev, runId]
        );
    };

    const handleCompare = () => {
        if (selectedRuns.length === 2) {
            const run1 = history.find((r: any) => r.run_id === selectedRuns[0]);
            const run2 = history.find((r: any) => r.run_id === selectedRuns[1]);
            setComparison({ run1, run2 });
        }
    };

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
                        {isLoading ? (
                            <LoadingSpinner />
                        ) : latestTrace ? (
                            <PowerGraph key={`${backend}-${latestTrace.run_id}`} data={latestTrace.power_trace} backend={backend} />
                        ) : (
                            <div className="h-full bg-card border rounded-lg flex items-center justify-center text-muted-foreground">
                                Waiting for data...
                            </div>
                        )}
                    </div>
                    <div className="bg-card border rounded-lg p-6 flex flex-col justify-center">
                        <h3 className="text-xl font-bold mb-4">Latest Run Stats</h3>
                        {isLoading ? (
                            <SkeletonCard />
                        ) : latestTrace ? (
                            <div className="space-y-4">
                                <div className="flex justify-between border-b border-border pb-2">
                                    <span className="text-muted-foreground flex items-center">
                                        Latency
                                        <InfoTooltip text="Response generation time" />
                                    </span>
                                    <span className="font-mono text-xl">{Math.round(latestTrace.latency_ms)} ms</span>
                                </div>
                                <div className="flex justify-between border-b border-border pb-2">
                                    <span className="text-muted-foreground flex items-center">
                                        Energy
                                        <InfoTooltip text="Power consumed" />
                                    </span>
                                    <span className="font-mono text-xl text-yellow-400">{Math.round(latestTrace.energy_joules)} J</span>
                                </div>
                                <div className="flex justify-between pt-2">
                                    <span className="text-muted-foreground flex items-center">
                                        Efficiency (EDP)
                                        <InfoTooltip text="Lower = Better overall" />
                                    </span>
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
                <div className="space-y-4">
                    {selectedRuns.length === 2 && (
                        <div className="flex justify-end">
                            <button
                                onClick={handleCompare}
                                className="px-4 py-2 bg-primary text-primary-foreground rounded font-semibold hover:bg-primary/90 transition-colors"
                            >
                                Compare Selected Runs
                            </button>
                        </div>
                    )}
                    <HistoryTable
                        runs={history}
                        selectedRuns={selectedRuns}
                        onToggleSelection={handleToggleSelection}
                    />
                </div>
            )}

            {comparison && (
                <ComparisonView
                    comparison={comparison}
                    onClose={() => {
                        setComparison(null);
                        setSelectedRuns([]);
                    }}
                />
            )}
        </div>
    );
}
