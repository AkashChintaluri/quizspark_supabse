import { useNavigate } from 'react-router-dom';
import React, { useState, useEffect } from 'react';
import axios from 'axios';
import './SignupForm.css';

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

    useEffect(() => {
        if (showPopup) {
            const timer = setTimeout(() => {
                setShowPopup(false);
                navigate(formData.userType === 'student' ? '/student-login' : '/teacher-login');
            }, 2000);
            return () => clearTimeout(timer);
        }
    }, [showPopup, navigate, formData.userType]);

    const handleInputChange = (e) => {
        const { id, value } = e.target;
        setFormData((prev) => ({ ...prev, [id]: value }));
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        setIsLoading(true);
        setErrorMessage('');

        try {
            const apiUrl = import.meta.env.VITE_API_URL;
            if (!apiUrl) {
                throw new Error('API URL is not defined in environment variables');
            }
            const response = await axios.post(`${apiUrl}/signup`, formData);
            setShowPopup(true);
            console.log('Signup successful:', response.data);
        } catch (error) {
            const errorMsg =
                error.response?.data?.error === 'Registration failed' &&
                error.response?.data?.details?.code === '23505'
                    ? 'Username or email already exists.'
                    : error.response?.data?.error || 'Registration failed. Please try again.';
            setErrorMessage(errorMsg);
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
                    <div className="form-group">
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
                    <div className="form-group">
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
                    <div className="form-group select-group">
                        <select
                            id="userType"
                            value={formData.userType}
                            onChange={handleInputChange}
                            disabled={isLoading}
                        >
                            <option value="student">Student</option>
                            <option value="teacher">Teacher</option>
                        </select>
                        <span className="select-placeholder">I am a</span>
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
                    ✅ Account created successfully! Redirecting to login...
                </div>
            )}
        </div>
    );
}

export default SignupForm;