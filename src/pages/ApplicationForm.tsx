import React, { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { Upload, ArrowRight, Check, AlertCircle } from 'lucide-react';

interface ApplicationFormProps {
  programId: string;
}

const questions = [
  {
    id: 'personal_info',
    title: 'Personal Information',
    fields: [
      { id: 'full_name', label: 'Full Name', type: 'text' },
      { id: 'date_of_birth', label: 'Date of Birth', type: 'date' },
      { id: 'nationality', label: 'Nationality', type: 'text' },
      { id: 'passport_number', label: 'Passport Number', type: 'text' },
    ]
  },
  {
    id: 'contact_info',
    title: 'Contact Information',
    fields: [
      { id: 'email', label: 'Email Address', type: 'email' },
      { id: 'phone', label: 'Phone Number', type: 'tel' },
      { id: 'current_address', label: 'Current Address', type: 'textarea' },
    ]
  },
  {
    id: 'education',
    title: 'Education Background',
    fields: [
      { id: 'highest_education', label: 'Highest Level of Education', type: 'select', 
        options: ['High School', 'Bachelor\'s', 'Master\'s', 'PhD'] },
      { id: 'field_of_study', label: 'Field of Study', type: 'text' },
      { id: 'graduation_year', label: 'Year of Graduation', type: 'number' },
    ]
  },
  {
    id: 'work_experience',
    title: 'Work Experience',
    fields: [
      { id: 'current_occupation', label: 'Current Occupation', type: 'text' },
      { id: 'years_of_experience', label: 'Years of Experience', type: 'number' },
      { id: 'skills', label: 'Key Skills', type: 'textarea' },
    ]
  },
];

const requiredDocuments = [
  { id: 'passport', label: 'Passport' },
  { id: 'education_certificate', label: 'Education Certificate' },
  { id: 'resume', label: 'Resume/CV' },
  { id: 'police_clearance', label: 'Police Clearance' },
  { id: 'language_test', label: 'Language Test Results' },
  { id: 'work_experience', label: 'Work Experience Letters' }
];

export default function ApplicationForm() {
  const { id: applicationId } = useParams();
  const { user } = useAuth();
  const navigate = useNavigate();
  const [currentStep, setCurrentStep] = useState(0);
  const [formData, setFormData] = useState<Record<string, any>>({});
  const [documents, setDocuments] = useState<Record<string, File>>({});
  const [loading, setLoading] = useState(false);
  const [showDocumentError, setShowDocumentError] = useState(false);

  const handleInputChange = (fieldId: string, value: string) => {
    setFormData(prev => ({
      ...prev,
      [fieldId]: value
    }));
  };

  const handleFileUpload = async (documentType: string, file: File) => {
    setDocuments(prev => ({
      ...prev,
      [documentType]: file
    }));
    setShowDocumentError(false);
  };

  const validateDocuments = () => {
    const missingDocuments = requiredDocuments.filter(doc => !documents[doc.id]);
    return missingDocuments.length === 0;
  };

  const handleSubmit = async () => {
    if (!applicationId || !user) return;
    
    if (!validateDocuments()) {
      setShowDocumentError(true);
      return;
    }

    setLoading(true);
    try {
      // Save questionnaire responses
      const { error: questionnaireError } = await supabase
        .from('application_questionnaire')
        .insert([{
          application_id: applicationId,
          questions,
          answers: formData
        }]);

      if (questionnaireError) throw questionnaireError;

      // Upload documents
      for (const [docType, file] of Object.entries(documents)) {
        const fileExt = file.name.split('.').pop();
        const filePath = `${user.id}/${applicationId}/${docType}.${fileExt}`;

        const { error: uploadError } = await supabase.storage
          .from('documents')
          .upload(filePath, file);

        if (uploadError) throw uploadError;

        const { error: docError } = await supabase
          .from('application_documents')
          .insert([{
            application_id: applicationId,
            document_type: docType,
            file_path: filePath
          }]);

        if (docError) throw docError;
      }

      // Update application status
      const { error: updateError } = await supabase
        .from('applications')
        .update({
          questionnaire_completed: true,
          documents_completed: true,
          status: 'submitted'
        })
        .eq('id', applicationId);

      if (updateError) throw updateError;

      navigate('/applications');
    } catch (error) {
      console.error('Error submitting application:', error);
      alert('Failed to submit application. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const currentSection = questions[currentStep];

  return (
    <div className="max-w-3xl mx-auto py-8">
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <h1 className="text-2xl font-bold text-gray-900">
            Immigration Program Application
          </h1>
          <span className="text-sm text-gray-500">
            Step {currentStep + 1} of {questions.length}
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-indigo-600 h-2 rounded-full transition-all duration-300"
            style={{ width: `${((currentStep + 1) / questions.length) * 100}%` }}
          />
        </div>
      </div>

      <div className="bg-white shadow-sm rounded-lg p-6">
        <h2 className="text-xl font-semibold mb-6">{currentSection.title}</h2>

        <div className="space-y-6">
          {currentSection.fields.map((field) => (
            <div key={field.id}>
              <label htmlFor={field.id} className="block text-sm font-medium text-gray-700">
                {field.label}
              </label>
              {field.type === 'select' ? (
                <select
                  id={field.id}
                  value={formData[field.id] || ''}
                  onChange={(e) => handleInputChange(field.id, e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                >
                  <option value="">Select an option</option>
                  {field.options?.map((option) => (
                    <option key={option} value={option}>{option}</option>
                  ))}
                </select>
              ) : field.type === 'textarea' ? (
                <textarea
                  id={field.id}
                  value={formData[field.id] || ''}
                  onChange={(e) => handleInputChange(field.id, e.target.value)}
                  rows={3}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              ) : (
                <input
                  type={field.type}
                  id={field.id}
                  value={formData[field.id] || ''}
                  onChange={(e) => handleInputChange(field.id, e.target.value)}
                  className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                />
              )}
            </div>
          ))}
        </div>

        {currentStep === questions.length - 1 && (
          <div className="mt-8">
            <h3 className="text-lg font-medium mb-4">Required Documents</h3>
            {showDocumentError && (
              <div className="mb-4 p-4 bg-red-50 rounded-md">
                <div className="flex items-center">
                  <AlertCircle className="h-5 w-5 text-red-400 mr-2" />
                  <p className="text-sm text-red-700">
                    Please upload all required documents before submitting your application.
                  </p>
                </div>
              </div>
            )}
            <div className="space-y-4">
              {requiredDocuments.map((doc) => (
                <div key={doc.id} className="flex items-center justify-between p-4 border rounded-lg">
                  <div className="flex items-center space-x-2">
                    <span className="text-sm font-medium text-gray-700">
                      {doc.label}
                    </span>
                    <span className="text-xs text-red-500">*Required</span>
                  </div>
                  {documents[doc.id] ? (
                    <div className="flex items-center text-green-600">
                      <Check className="h-5 w-5 mr-2" />
                      <span className="text-sm">Uploaded</span>
                    </div>
                  ) : (
                    <label className="cursor-pointer inline-flex items-center px-3 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50">
                      <Upload className="h-5 w-5 mr-2" />
                      Upload
                      <input
                        type="file"
                        className="hidden"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) handleFileUpload(doc.id, file);
                        }}
                        accept=".pdf,.jpg,.jpeg,.png"
                      />
                    </label>
                  )}
                </div>
              ))}
            </div>
          </div>
        )}

        <div className="mt-8 flex justify-between">
          <button
            type="button"
            onClick={() => setCurrentStep(prev => prev - 1)}
            className={`inline-flex items-center px-4 py-2 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 ${
              currentStep === 0 ? 'invisible' : ''
            }`}
          >
            Previous
          </button>
          
          {currentStep === questions.length - 1 ? (
            <button
              type="button"
              onClick={handleSubmit}
              disabled={loading}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? 'Submitting...' : 'Submit Application'}
            </button>
          ) : (
            <button
              type="button"
              onClick={() => setCurrentStep(prev => prev + 1)}
              className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
            >
              Next
              <ArrowRight className="ml-2 h-5 w-5" />
            </button>
          )}
        </div>
      </div>
    </div>
  );
}