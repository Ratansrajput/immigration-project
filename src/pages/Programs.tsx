import React, { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { FileText, ArrowRight } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';

interface Program {
  id: string;
  name: string;
  description: string;
  required_documents: string[];
}

export default function Programs() {
  const [programs, setPrograms] = useState<Program[]>([]);
  const [loading, setLoading] = useState(true);
  const navigate = useNavigate();
  const { user } = useAuth();

  useEffect(() => {
    async function loadPrograms() {
      try {
        const { data, error } = await supabase
          .from('programs')
          .select('*')
          .order('name');
        
        if (error) throw error;
        setPrograms(data || []);
      } catch (error) {
        console.error('Error loading programs:', error);
      } finally {
        setLoading(false);
      }
    }

    loadPrograms();
  }, []);

  const handleApply = async (programId: string) => {
    try {
      const { data, error } = await supabase
        .from('applications')
        .insert([
          { program_id: programId, user_id: user?.id, status: 'pending' }
        ])
        .select()
        .single();

      if (error) throw error;
      
      // Redirect to the application form with the new application ID
      navigate(`/application-form/${data.id}`);
    } catch (error) {
      console.error('Error creating application:', error);
      alert('Failed to create application. Please try again.');
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
    <div>
      <h1 className="text-2xl font-bold text-gray-900 mb-6">Immigration Programs</h1>
      
      <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {programs.map((program) => (
          <div
            key={program.id}
            className="bg-white rounded-lg shadow-md overflow-hidden hover:shadow-lg transition-shadow duration-300"
          >
            <div className="p-6">
              <div className="flex items-center justify-between mb-4">
                <FileText className="h-8 w-8 text-indigo-600" />
                <span className="text-sm font-medium text-gray-500">
                  {program.required_documents.length} Required Documents
                </span>
              </div>
              
              <h3 className="text-xl font-semibold text-gray-900 mb-2">
                {program.name}
              </h3>
              
              <p className="text-gray-600 mb-4 line-clamp-3">
                {program.description}
              </p>

              <div className="space-y-2">
                <h4 className="text-sm font-medium text-gray-900">Required Documents:</h4>
                <ul className="text-sm text-gray-600 space-y-1">
                  {program.required_documents.map((doc, index) => (
                    <li key={index} className="flex items-center">
                      <ArrowRight className="h-4 w-4 mr-2 text-indigo-600" />
                      {doc}
                    </li>
                  ))}
                </ul>
              </div>

              <button
                onClick={() => handleApply(program.id)}
                className="mt-6 w-full inline-flex items-center justify-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
              >
                Apply Now
              </button>
            </div>
          </div>
        ))}
      </div>

      {programs.length === 0 && (
        <div className="text-center py-12">
          <FileText className="mx-auto h-12 w-12 text-gray-400" />
          <h3 className="mt-2 text-sm font-medium text-gray-900">No programs available</h3>
          <p className="mt-1 text-sm text-gray-500">Check back later for new immigration programs.</p>
        </div>
      )}
    </div>
  );
}