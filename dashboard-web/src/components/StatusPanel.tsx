import { Activity, Server, Cpu } from 'lucide-react';

export function StatusPanel({ status }: { status: any }) {
    return (
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mb-6">
            <div className="bg-card border rounded-lg p-4 flex items-center gap-4">
                <div className="p-3 bg-blue-500/20 rounded-full">
                    <Activity className="w-6 h-6 text-blue-400" />
                </div>
                <div>
                    <p className="text-sm text-muted-foreground">Status</p>
                    <p className="text-xl font-bold capitalize">{status.status}</p>
                </div>
            </div>

            <div className="bg-card border rounded-lg p-4 flex items-center gap-4">
                <div className="p-3 bg-purple-500/20 rounded-full">
                    <Server className="w-6 h-6 text-purple-400" />
                </div>
                <div>
                    <p className="text-sm text-muted-foreground">Current Step</p>
                    <p className="text-xl font-bold">{status.step_name || "Idle"}</p>
                </div>
            </div>

            <div className="bg-card border rounded-lg p-4 flex items-center gap-4">
                <div className="p-3 bg-green-500/20 rounded-full">
                    <Cpu className="w-6 h-6 text-green-400" />
                </div>
                <div>
                    <p className="text-sm text-muted-foreground">Progress</p>
                    <p className="text-xl font-bold">{(status.progress * 100).toFixed(0)}%</p>
                </div>
            </div>
        </div>
    );
}
