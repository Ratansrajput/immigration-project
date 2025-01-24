import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(import.meta.env.VITE_GEMINI_API_KEY);

export async function analyzeProgramFit(answers: Record<string, string>) {
  const model = genAI.getGenerativeModel({ model: "gemini-pro" });

  const prompt = `
    Based on these applicant responses, recommend the best immigration programs and countries:
    ${JSON.stringify(answers, null, 2)}
    
    Consider:
    1. Educational background
    2. Work experience
    3. Language proficiency
    4. Financial capacity
    5. Personal preferences
    
    Provide recommendations in this JSON format:
    {
      "topPrograms": [
        { "name": "program name", "country": "country", "fitScore": 0-100, "reasons": [] }
      ]
    }
  `;

  const result = await model.generateContent(prompt);
  const response = await result.response;
  const text = response.text();

  try {
    return JSON.parse(text);
  } catch (error) {
    console.error('Error parsing Gemini response:', error);
    throw new Error('Failed to parse program recommendations');
  }
}