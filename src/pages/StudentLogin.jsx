import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import axios from 'axios';
import { FaUser, FaLock, FaEye, FaEyeSlash } from 'react-icons/fa';
import './Login.css';

const API_URL = 'http://ec2-3-110-27-110.ap-south-1.compute.amazonaws.com:3000';

function StudentLogin() {
    const navigate = useNavigate();
    const [formData, setFormData] = useState({ username: '', password: '' });
    const [isLoading, setIsLoading] = useState(false);
    const [showPopup, setShowPopup] = useState(false);
    const [errorMessage, setErrorMessage] = useState('');
    const [showPassword, setShowPassword] = useState(false);

    useEffect(() => {
        if (showPopup) {
            const timer = setTimeout(() => {
                setShowPopup(false);
                navigate('/student-dashboard');
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showPopup, navigate]);

    const handleInputChange = (e) => {
        const { id, value } = e.target;
        setFormData((prev) => ({ ...prev, [id]: value }));
    };

    const togglePasswordVisibility = () => {
        setShowPassword((prev) => !prev);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsLoading(true);
        setErrorMessage('');

        try {
            const response = await axios.post(`${API_URL}/login`, {
                ...formData,
                userType: 'student',
            });

            if (response.data.success) {
                localStorage.setItem('user', JSON.stringify(response.data.user));
                setShowPopup(true);
            } else {
                setErrorMessage('Invalid username or password');
            }
        } catch (error) {
            const serverError = error.response?.data?.error || error.message;
            setErrorMessage(serverError || 'Login failed. Please try again.');
            console.error('Login error:', error);
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="login">
            <div className="login-content">
                <h2>Student Login</h2>
                <form className="login-form" onSubmit={handleSubmit}>
                    <div className="form-group">
                        <div className="input-wrapper">
                            <span className="icon">
                                <FaUser />
                            </span>
                            <input
                                type="text"
                                id="username"
                                value={formData.username}
                                onChange={handleInputChange}
                                required
                                placeholder="Enter username"
                                autoComplete="username"
                                disabled={isLoading}
                                aria-label="Username"
                            />
                        </div>
                    </div>
                    <div className="form-group">
                        <div className="input-wrapper password-wrapper">
                            <span className="icon">
                                <FaLock />
                            </span>
                            <input
                                type={showPassword ? 'text' : 'password'}
                                id="password"
                                value={formData.password}
                                onChange={handleInputChange}
                                required
                                placeholder="Enter password"
                                autoComplete="current-password"
                                disabled={isLoading}
                                aria-label="Password"
                            />
                            <button
                                type="button"
                                className="password-toggle"
                                onClick={togglePasswordVisibility}
                                aria-label={showPassword ? 'Hide password' : 'Show password'}
                                tabIndex={-1}
                            >
                                {showPassword ? <FaEyeSlash /> : <FaEye />}
                            </button>
                        </div>
                    </div>
                    {errorMessage && (
                        <div className="error-message">
                            <FaUser className="icon" />
                            {errorMessage}
                        </div>
                    )}
                    <button
                        type="submit"
                        className="login-button"
                        disabled={isLoading}
                        aria-label="Login"
                    >
                        {isLoading ? 'Logging in...' : 'Login'}
                    </button>
                    <div className="signup-link">
                        Don't have an account?{' '}
                        <button
                            type="button"
                            className="link-button"
                            onClick={() => navigate('/signup')}
                            aria-label="Navigate to signup"
                        >
                            Sign up here
                        </button>
                    </div>
                </form>
            </div>
            {showPopup && (
                <div className="popup success">
                    <FaUser className="icon" />
                    Login successful! Redirecting to dashboard...
                </div>
            )}
        </div>
    );
}

export default StudentLogin;
