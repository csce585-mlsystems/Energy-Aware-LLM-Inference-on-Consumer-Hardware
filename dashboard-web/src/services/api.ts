import axios from 'axios';

const API_URL = 'http://localhost:5000';

export const api = {
    getHistory: async () => {
        const response = await axios.get(`${API_URL}/history`);
        return response.data;
    },
    getLatestTrace: async (backend = 'gpu') => {
        const response = await axios.get(`${API_URL}/latest_trace`, {
            params: { backend }
        });
        return response.data;
    },
    getStatus: async () => {
        const response = await axios.get(`${API_URL}/status`);
        return response.data;
    }
};
