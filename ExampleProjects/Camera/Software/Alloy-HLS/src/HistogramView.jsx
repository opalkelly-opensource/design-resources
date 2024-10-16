import React from 'react';
import PropTypes from 'prop-types';
import { Bar } from 'react-chartjs-2';
import { Chart as ChartJS, CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend } from 'chart.js';

ChartJS.register(CategoryScale, LinearScale, BarElement, Title, Tooltip, Legend);

// Define the HistogramView component that receives data arrays and dimensions as props
const HistogramView = ({ red, blue, green, width, height }) => {
    const chartData = {
        labels: red.map((_, index) => index),
        datasets: [
            {
                label: 'Red',
                data: red, 
                backgroundColor: 'rgba(255, 0, 0, 1)', 
                borderColor: 'rgba(255, 0, 0, 1)', 
                borderWidth: 1,
            },
            {
                label: 'Green',
                data: green, 
                backgroundColor: 'rgba(0, 255, 0, 1)',
                borderColor: 'rgba(0, 255, 0, 1)', 
                borderWidth: 1,
            },
            {
                label: 'Blue',
                data: blue, 
                backgroundColor: 'rgba(0, 0, 255, 1)',
                borderColor: 'rgba(0, 0, 255, 1)',
                borderWidth: 1,
            }
        ]
    };

    return (
        <div style={{ width, height }}> 
            <Bar 
                data={chartData}
                options={{
                    responsive: true,
                    plugins: {
                        legend: { display: true },
                        tooltip: { 
                            callbacks: { 
                                label: (context) => `Value: ${context.raw}` 
                            } 
                        },
                    },
                    scales: {
                        x: { beginAtZero: true },
                        y: { beginAtZero: true }
                    }
                }} 
            />
        </div>
    );
};

// Define prop types for the component
HistogramView.propTypes = {
    red: PropTypes.arrayOf(PropTypes.number).isRequired, 
    blue: PropTypes.arrayOf(PropTypes.number).isRequired,
    green: PropTypes.arrayOf(PropTypes.number).isRequired,
    width: PropTypes.number, 
    height: PropTypes.number,
};

// Default props for width and height
HistogramView.defaultProps = {
    width: 400,
    height: 400,
};

export default HistogramView; 
