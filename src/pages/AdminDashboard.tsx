import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { Plus, Users, FileText, CheckCircle, XCircle, Brain, FileSearch, MessageSquare } from 'lucide-react';
import DocumentUploader from '../components/DocumentUploader';
import ProgramQuestionnaire from '../components/ProgramQuestionnaire';

interface Program {
  id: string;
  name: string;
  description: string;
  required_documents: string[];
}

interface Application {
  id: string;
  status: string;
  created_at: string;
  user: {
    full_name: string;
  };
  program: {
    name: string;
  };
}

export default function AdminDashboard() {
  const [activeTab, setActiveTab] = useState('overview');
  const [programs, setPrograms] = useState<Program[]>([]);
  const [applications, setApplications] = useState<Application[]>([]);
  const [loading, setLoading] = useState(true);
  const [showNewProgram, setShowNewProgram] = useState(false);
  const [newProgram, setNewProgram] = useState({
    name: '',
    description: '',
    documents: ['']
  });

  useEffect(() => {
    loadData();
  }, []);

  async function loadData() {
    try {
      const [programsResponse, applicationsResponse] = await Promise.all([
        supabase.from('programs').select('*').order('created_at', { ascending: false }),
        supabase
          .from('applications')
          .select(`
            id,
            status,
            created_at,
            user:users(full_name),
            program:programs(name)
          `)
          .order('created_at', { ascending: false })
      ]);

      if (programsResponse.error) throw programsResponse.error;
      if (applicationsResponse.error) throw applicationsResponse.error;

      setPrograms(programsResponse.data || []);
      setApplications(applicationsResponse.data || []);
    } catch (error) {
      console.error('Error loading data:', error);
    } finally {
      setLoading(false);
    }
  }

  const handleAddDocument = () => {
    setNewProgram(prev => ({
      ...prev,
      documents: [...prev.documents, '']
    }));
  };

  const handleDocumentChange = (index: number, value: string) => {
    const updatedDocuments = [...newProgram.documents];
    updatedDocuments[index] = value;
    setNewProgram(prev => ({
      ...prev,
      documents: updatedDocuments
    }));
  };

  const handleCreateProgram = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const { error } = await supabase
        .from('programs')
        .insert([{
          name: newProgram.name,
          description: newProgram.description,
          required_documents: newProgram.documents.filter(doc => doc.trim() !== '')
        }]);

      if (error) throw error;

      setNewProgram({ name: '', description: '', documents: [''] });
      setShowNewProgram(false);
      loadData();
    } catch (error) {
      console.error('Error creating program:', error);
      alert('Failed to create program. Please try again.');
    }
  };

  const updateApplicationStatus = async (applicationId: string, status: string) => {
    try {
      const { error } = await supabase
        .from('applications')
        .update({ status })
        .eq('id', applicationId);

      if (error) throw error;
      loadData();
    } catch (error) {
      console.error('Error updating application:', error);
      alert('Failed to update application status. Please try again.');
    }
  };

  if (loading) {
    return (
      <div className="flex justify-center items-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-indigo-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex space-x-8">
          <button
            onClick={() => setActiveTab('overview')}
            className={`${
              activeTab === 'overview'
                ? 'border-indigo-500 text-indigo-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
          >
            Overview
          </button>
          <button
            onClick={() => setActiveTab('document-validation')}
            className={`${
              activeTab === 'document-validation'
                ? 'border-indigo-500 text-indigo-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
          >
            Document Validation
          </button>
          <button
            onClick={() => setActiveTab('program-matcher')}
            className={`${
              activeTab === 'program-matcher'
                ? 'border-indigo-500 text-indigo-600'
                : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
            } whitespace-nowrap py-4 px-1 border-b-2 font-medium text-sm`}
          >
            Program Matcher
          </button>
        </nav>
      </div>

      {activeTab === 'overview' && (
        <>
          <div>
            <div className="flex justify-between items-center mb-4">
              <h2 className="text-2xl font-bold text-gray-900">Immigration Programs</h2>
              <button
                onClick={() => setShowNewProgram(true)}
                className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
              >
                <Plus className="h-5 w-5 mr-2" />
                New Program
              </button>
            </div>

            {showNewProgram && (
              <form onSubmit={handleCreateProgram} className="bg-white shadow sm:rounded-lg p-6 mb-6">
                <div className="space-y-4">
                  <div>
                    <label htmlFor="name" className="block text-sm font-medium text-gray-700">
                      Program Name
                    </label>
                    <input
                      type="text"
                      id="name"
                      value={newProgram.name}
                      onChange={(e) => setNewProgram(prev => ({ ...prev, name: e.target.value }))}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      required
                    />
                  </div>

                  <div>
                    <label htmlFor="description" className="block text-sm font-medium text-gray-700">
                      Description
                    </label>
                    <textarea
                      id="description"
                      value={newProgram.description}
                      onChange={(e) => setNewProgram(prev => ({ ...prev, description: e.target.value }))}
                      rows={3}
                      className="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                      required
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Required Documents
                    </label>
                    {newProgram.documents.map((doc, index) => (
                      <div key={index} className="flex mb-2">
                        <input
                          type="text"
                          value={doc}
                          onChange={(e) => handleDocumentChange(index, e.target.value)}
                          className="flex-1 rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500"
                          placeholder="Document name"
                          required
                        />
                      </div>
                    ))}
                    <button
                      type="button"
                      onClick={handleAddDocument}
                      className="mt-2 inline-flex items-center px-3 py-1 border border-gray-300 shadow-sm text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50"
                    >
                      <Plus className="h-4 w-4 mr-1" />
                      Add Document
                    </button>
                  </div>

                  <div className="flex justify-end space-x-3">
                    <button
                      type="button"
                      onClick={() => setShowNewProgram(false)}
                      className="px-4 py-2 border border-gray-300 rounded-md shadow-sm text-sm font-medium text-gray-700 bg-white hover:bg-gray-50"
                    >
                      Cancel
                    </button>
                    <button
                      type="submit"
                      className="px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700"
                    >
                      Create Program
                    </button>
                  </div>
                </div>
              </form>
            )}

            <div className="bg-white shadow overflow-hidden sm:rounded-md">
              <ul className="divide-y divide-gray-200">
                {programs.map((program) => (
                  <li key={program.id} className="px-4 py-4 sm:px-6">
                    <div>
                      <h3 className="text-lg font-medium text-gray-900">{program.name}</h3>
                      <p className="mt-1 text-sm text-gray-600">{program.description}</p>
                      <div className="mt-2">
                        <h4 className="text-sm font-medium text-gray-700">Required Documents:</h4>
                        <ul className="mt-1 text-sm text-gray-500 list-disc list-inside">
                          {program.required_documents.map((doc, index) => (
                            <li key={index}>{doc}</li>
                          ))}
                        </ul>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div>
            <h2 className="text-2xl font-bold text-gray-900 mb-4">Recent Applications</h2>
            <div className="bg-white shadow overflow-hidden sm:rounded-md">
              <ul className="divide-y divide-gray-200">
                {applications.map((application) => (
                  <li key={application.id} className="px-4 py-4 sm:px-6">
                    <div className="flex items-center justify-between">
                      <div>
                        <h4 className="text-lg font-medium text-gray-900">
                          {application.user.full_name}
                        </h4>
                        <p className="text-sm text-gray-500">
                          Program: {application.program.name}
                        </p>
                        <p className="text-sm text-gray-500">
                          Submitted: {new Date(application.created_at).toLocaleDateString()}
                        </p>
                      </div>
                      <div className="flex items-center space-x-2">
                        <button
                          onClick={() => updateApplicationStatus(application.id, 'approved')}
                          className="inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-green-600 hover:bg-green-700"
                        >
                          <CheckCircle className="h-5 w-5" />
                        </button>
                        <button
                          onClick={() => updateApplicationStatus(application.id, 'rejected')}
                          className="inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-red-600 hover:bg-red-700"
                        >
                          <XCircle className="h-5 w-5" />
                        </button>
                      </div>
                    </div>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </>
      )}

      {activeTab === 'document-validation' && (
        <div className="bg-white shadow-sm rounded-lg p-6">
          <h2 className="text-xl font-bold mb-6">Document Validation</h2>
          <DocumentUploader
            onUploadComplete={(result) => {
              console.log('Document validation result:', result);
            }}
            documentType="identification"
          />
        </div>
      )}

      {activeTab === 'program-matcher' && (
        <div className="bg-white shadow-sm rounded-lg p-6">
          <h2 className="text-xl font-bold mb-6">Program Matcher</h2>
          <ProgramQuestionnaire />
        </div>
      )}
    </div>
  );
}