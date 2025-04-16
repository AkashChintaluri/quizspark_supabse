import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './TeacherList.css';

const API_BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000';

function TeacherList({ studentId }) {
    const [teachers, setTeachers] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showDropdown, setShowDropdown] = useState(false);
    const [searchTerm, setSearchTerm] = useState('');
    const [subscriptions, setSubscriptions] = useState(new Set());

    useEffect(() => {
        fetchTeachers();
    }, [studentId]);

    const fetchTeachers = async () => {
        try {
            const [teachersRes, subsRes] = await Promise.all([
                axios.get(`${API_BASE_URL}/api/teachers`),
                axios.get(`${API_BASE_URL}/api/subscriptions/${studentId}`)
            ]);
            
            if (Array.isArray(teachersRes.data)) {
                setTeachers(teachersRes.data);
            } else {
                console.warn('Teachers response is not an array:', teachersRes.data);
                setTeachers([]);
                setError('Invalid teachers data received.');
            }

            if (Array.isArray(subsRes.data)) {
                setSubscriptions(new Set(subsRes.data.map(sub => sub.id)));
            } else {
                console.warn('Subscriptions response is not an array:', subsRes.data);
                setSubscriptions(new Set());
                setError(subsRes.data?.error || 'Invalid subscriptions data received.');
            }
        } catch (err) {
            console.error('Error fetching data:', err);
            setError(err.response?.data?.error || 'Failed to fetch teacher data.');
        } finally {
            setLoading(false);
        }
    };

    const handleSubscribe = async (teacherId) => {
        try {
            await axios.post(`${API_BASE_URL}/api/subscribe`, {
                student_id: studentId,
                teacher_id: teacherId
            });
            fetchTeachers();
        } catch (err) {
            setError('Failed to subscribe to teacher');
        }
    };

    const handleUnsubscribe = async (teacherId) => {
        try {
            await axios.post(`${API_BASE_URL}/api/unsubscribe`, {
                student_id: studentId,
                teacher_id: teacherId
            });
            fetchTeachers();
        } catch (err) {
            setError('Failed to unsubscribe from teacher');
        }
    };

    const subscribedTeachers = teachers.filter(teacher => subscriptions.has(teacher.id));
    const unsubscribedTeachers = teachers.filter(teacher => !subscriptions.has(teacher.id));
    const filteredUnsubscribedTeachers = unsubscribedTeachers.filter(teacher =>
        teacher.username.toLowerCase().includes(searchTerm.toLowerCase())
    );

    if (loading) {
        return <div className="teacher-list"><div className="loading">Loading teachers...</div></div>;
    }

    if (error) {
        return <div className="teacher-list"><div className="error-message">{error}</div></div>;
    }

    return (
        <div className="teacher-list">
            <h3>Your Teachers</h3>
            {subscribedTeachers.length === 0 ? (
                <div className="no-teachers">You haven't subscribed to any teachers yet.</div>
            ) : (
                <div className="teacher-grid">
                    {subscribedTeachers.map((teacher) => (
                        <div key={teacher.id} className="teacher-card">
                            <div className="teacher-info">
                                <h4>{teacher.username}</h4>
                                <p>{teacher.email}</p>
                            </div>
                            <div className="teacher-actions">
                                <span className="status subscribed">Subscribed</span>
                                <button
                                    className="subscribed-btn"
                                    onClick={() => handleUnsubscribe(teacher.id)}
                                >
                                    Unsubscribe
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            )}

            <div className="unsubscribed-section">
                <button
                    className="dropdown-toggle"
                    onClick={() => setShowDropdown(!showDropdown)}
                >
                    {showDropdown ? 'Hide Available Teachers' : 'Show Available Teachers'}
                </button>

                {showDropdown && (
                    <div className="dropdown-menu">
                        <input
                            type="text"
                            className="search-input"
                            placeholder="Search teachers..."
                            value={searchTerm}
                            onChange={(e) => setSearchTerm(e.target.value)}
                        />
                        {filteredUnsubscribedTeachers.length === 0 ? (
                            <div className="no-teachers">No teachers found</div>
                        ) : (
                            <ul className="teacher-dropdown-list">
                                {filteredUnsubscribedTeachers.map((teacher) => (
                                    <li key={teacher.id} className="dropdown-item">
                                        <span>{teacher.username}</span>
                                        <button
                                            className="subscribe-btn"
                                            onClick={() => handleSubscribe(teacher.id)}
                                        >
                                            Subscribe
                                        </button>
                                    </li>
                                ))}
                            </ul>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}

export default TeacherList;