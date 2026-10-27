// Edge Function: explain-question
// Generates explanations for exam questions using Google Gemini API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const GEMINI_API_KEY = Deno.env.get('GEMINI_API_KEY') || ''

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { question, correctAnswer, studentAnswer } = await req.json()

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build the prompt based on whether student answer is provided
    let prompt = `As an educational tutor, explain this exam question and its correct answer:\n\n`
    prompt += `Question: ${question}\n\n`
    prompt += `Correct Answer: ${correctAnswer}\n\n`
    
    if (studentAnswer) {
      prompt += `The student answered: ${studentAnswer}\n\n`
      prompt += `Please:\n`
      prompt += `1. Explain why the correct answer is right\n`
      prompt += `2. If the student was wrong, explain their misconception\n`
      prompt += `3. Provide a clear step-by-step explanation\n\n`
    } else {
      prompt += `Please provide:\n`
      prompt += `1. A clear explanation of why this is the correct answer\n`
      prompt += `2. Step-by-step reasoning\n`
      prompt += `3. Any key concepts the student should understand\n\n`
    }
    
    prompt += `Keep the explanation concise, encouraging, and educational (under 200 words).`

    // Call Gemini API
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          contents: [{
            parts: [{ text: prompt }]
          }],
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 512,
          },
        }),
      }
    )

    if (!response.ok) {
      const error = await response.text()
      console.error('Gemini API error:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to get explanation' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const data = await response.json()
    const explanation = data.candidates?.[0]?.content?.parts?.[0]?.text || 
                       "I couldn't generate an explanation. Please try again."

    return new Response(
      JSON.stringify({ explanation }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
