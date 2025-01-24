import React, { useState } from 'react';
import { analyzeProgramFit } from '../services/programMatcher';
import { ArrowRight, Loader } from 'lucide-react';

const questions = [
  {
    id: 'education',
    question: 'What is your highest level of education?',
    options: [
      'High School',
      'Bachelor\'s Degree',
      'Master\'s Degree',
      'Doctorate',
    ],
  },
  {
    id: 'workExperience',
    question: 'How many years of work experience do you have?',
    options: [
      'Less than 1 year',
      '1-3 years',
      '3-5 years',
      '5+ years',
    ],
  },
  {
    id: 'language',
    question: 'What is your English proficiency level?',
    options: [
      'Basic',
      'Intermediate',
      'Advanced',
      'Native/Bilingual',
    ],
  },
  {
    id: 'budget',
    question: 'What is your budget range for the immigration process?',
    options: [
      'Under $5,000',
      '$5,000 - $10,000',
      '$10,000 - $20,000',
      'Above $20,000',
    ],
  },
  {
    id: 'timeline',
    question: 'What is your preferred timeline for immigration?',
    options: [
      'Within 6 months',
      '6-12 months',
      '1-2 years',
      'Flexible',
    ],
  },
];

export default function ProgramQuestionnaire() {
  const [currentQuestion, setCurrentQuestion] = useState(0);
  const [answers, setAnswers] = useState<Record<string, string>>({});
  const [recommendations, setRecommendations] = useState<any>(null);
  const [loading, setLoading] = useState(false);

  const handleAnswer = async (answer: string) => {
    const newAnswers = {
      ...answers,
      [questions[currentQuestion].id]: answer,
    };
    setAnswers(newAnswers);

    if (currentQuestion < questions.length - 1) {
      setCurrentQuestion(currentQuestion + 1);
    } else {
      setLoading(true);
      try {
        const result = await analyzeProgramFit(newAnswers);
        setRecommendations(result);
      } catch (error) {
        console.error('Error analyzing answers:', error);
        alert('Error generating recommendations. Please try again.');
      } finally {
        setLoading(false);
      }
    }
  };

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center p-8">
        <Loader className="h-8 w-8 animate-spin text-indigo-600 mb-4" />
        <p className="text-gray-600">Analyzing your responses...</p>
      </div>
    );
  }

  if (recommendations) {
    return (
      <div className="space-y-6">
        <h2 className="text-2xl font-bold text-gray-900">
          Recommended Programs
        </h2>
        <div className="grid gap-6 md:grid-cols-2">
          {recommendations.topPrograms.map((program: any, index: number) => (
            <div
              key={index}
              className="bg-white rounded-lg shadow-md p-6 border border-gray-200"
            >
              <div className="flex justify-between items-start">
                <div>
                  <h3 className="text-lg font-semibold text-gray-900">
                    {program.name}
                  </h3>
                  <p className="text-sm text-gray-500">{program.country}</p>
                </div>
                <div className="bg-indigo-100 text-indigo-800 text-sm font-medium px-2.5 py-0.5 rounded">
                  {program.fitScore}% Match
                </div>
              </div>
              <ul className="mt-4 space-y-2">
                {program.reasons.map((reason: string, idx: number) => (
                  <li key={idx} className="flex items-center text-sm text-gray-600">
                    <ArrowRight className="h-4 w-4 text-indigo-500 mr-2" />
                    {reason}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-2xl mx-auto">
      <div className="mb-8">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-semibold text-gray-900">
            Find Your Perfect Program
          </h2>
          <span className="text-sm text-gray-500">
            Question {currentQuestion + 1} of {questions.length}
          </span>
        </div>
        <div className="w-full bg-gray-200 rounded-full h-2">
          <div
            className="bg-indigo-600 h-2 rounded-full transition-all duration-300"
            style={{
              width: `${((currentQuestion + 1) / questions.length) * 100}%`,
            }}
          />
        </div>
      </div>

      <div className="bg-white rounded-lg shadow-md p-6">
        <h3 className="text-lg font-medium text-gray-900 mb-6">
          {questions[currentQuestion].question}
        </h3>
        <div className="space-y-3">
          {questions[currentQuestion].options.map((option) => (
            <button
              key={option}
              onClick={() => handleAnswer(option)}
              className="w-full text-left px-4 py-3 rounded-lg border border-gray-300 hover:border-indigo-500 hover:bg-indigo-50 transition-colors"
            >
              {option}
            </button>
          ))}
        </div>
      </div>
    </div>
  );
}