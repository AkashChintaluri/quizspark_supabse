import { useNavigate } from 'react-router-dom';
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { FaUser, FaEnvelope, FaLock, FaUserGraduate, FaChalkboardTeacher } from 'react-icons/fa';
import './SignupForm.css';

const API_URL = 'http://ec2-3-110-27-110.ap-south-1.compute.amazonaws.com:3000';

function SignupForm() {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({
        username: '',
        email: '',
        password: '',
        userType: 'student',
    });
    const [isLoading, setIsLoading] = useState(false);
    const [showPopup, setShowPopup] = useState(false);
    const [errorMessage, setErrorMessage] = useState('');
    const [showBlockedPopup, setShowBlockedPopup] = useState(false);

    useEffect(() => {
        if (showPopup) {
            const timer = setTimeout(() => {
                setShowPopup(false);
                navigate(formData.userType === 'student' ? '/student-login' : '/teacher-login');
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showPopup, navigate, formData.userType]);

    useEffect(() => {
        if (showBlockedPopup) {
            const timer = setTimeout(() => {
                setShowBlockedPopup(false);
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showBlockedPopup]);

    const handleInputChange = (e) => {
        const { id, value } = e.target;
        setFormData((prev) => ({ ...prev, [id]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsLoading(true);
        setErrorMessage('');

        // Check if email contains 'teach' for teacher signup
        if (formData.userType === 'teacher' && !formData.email.toLowerCase().includes('teach')) {
            setShowBlockedPopup(true);
            setIsLoading(false);
            return;
        }

        try {
            const response = await axios.post(`${API_URL}/signup`, {
                ...formData,
                userType: formData.userType.toLowerCase()
            });

            if (response.data.success) {
                localStorage.setItem('user', JSON.stringify(response.data.user));
                setShowPopup(true);
                setTimeout(() => {
                    navigate(formData.userType === 'student' ? '/student-dashboard' : '/teacher-dashboard');
                }, 1500);
            } else {
                setErrorMessage(response.data.message || 'Signup failed');
            }
        } catch (error) {
            const serverError = error.response?.data?.error || error.message;
            setErrorMessage(serverError || 'Signup failed. Please try again.');
            console.error('Signup error:', error);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="signup">
            <div className="signup-content">
                <h2>Join QuizSpark</h2>
                <form className="signup-form" onSubmit={handleSubmit}>
                    <div className="form-group">
                        <div className="input-wrapper">
                            <span className="icon"><FaUser /></span>
                            <input
                                type="text"
                                id="username"
                                value={formData.username}
                                onChange={handleInputChange}
                                required
                                placeholder="Username"
                                autoComplete="username"
                                disabled={isLoading}
                            />
                        </div>
                    </div>
                    <div className="form-group">
                        <div className="input-wrapper">
                            <span className="icon"><FaEnvelope /></span>
                            <input
                                type="email"
                                id="email"
                                value={formData.email}
                                onChange={handleInputChange}
                                required
                                placeholder="Email"
                                autoComplete="email"
                                disabled={isLoading}
                            />
                        </div>
                    </div>
                    <div className="form-group">
                        <div className="input-wrapper">
                            <span className="icon"><FaLock /></span>
                            <input
                                type="password"
                                id="password"
                                value={formData.password}
                                onChange={handleInputChange}
                                required
                                placeholder="Password"
                                autoComplete="new-password"
                                disabled={isLoading}
                            />
                        </div>
                    </div>
                    <div className="form-group select-group">
                        <div className="input-wrapper">
                            <span className="icon">
                                {formData.userType === 'student' ? <FaUserGraduate /> : <FaChalkboardTeacher />}
                            </span>
                            <select
                                id="userType"
                                value={formData.userType}
                                onChange={handleInputChange}
                                disabled={isLoading}
                            >
                                <option value="student">Student</option>
                                <option value="teacher">Teacher</option>
                            </select>
                        </div>
                    </div>
                    {errorMessage && <div className="error-message">{errorMessage}</div>}
                    <button
                        type="submit"
                        className="signup-button"
                        disabled={isLoading}
                    >
                        {isLoading ? 'Creating Account...' : 'Sign Up'}
                    </button>
                </form>
            </div>
            {showPopup && (
                <div className="popup success">
                    <FaUser className="icon" />
                    Signup successful! Redirecting to dashboard...
                </div>
            )}
            {showBlockedPopup && (
                <div className="popup error">
                    <FaUser className="icon" />
                    Teacher signup is blocked.
                </div>
            )}
        </div>
    );
}

export default SignupForm;
