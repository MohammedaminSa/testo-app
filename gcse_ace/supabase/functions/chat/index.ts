// Edge Function: chat
// Receives user messages and returns AI responses using Google Gemini API

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const rawKey = Deno.env.get('GEMINI_API_KEY') || ''
const GEMINI_API_KEY = rawKey.trim().replace(/^["']|["']$/g, '').trim()

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

let cachedModel: string | null = null

async function getAvailableModel(apiKey: string): Promise<string> {
  const envModel = Deno.env.get('GEMINI_MODEL')?.trim()
  if (envModel) return envModel
  if (cachedModel) return cachedModel

  try {
    const listRes = await fetch(`https://generativelanguage.googleapis.com/v1beta/models?key=${apiKey}`)
    if (listRes.ok) {
      const data = await listRes.json()
      const models: Array<{ name: string; supportedGenerationMethods?: string[] }> = data.models || []
      
      const generateModels = models
        .filter(m => m.supportedGenerationMethods?.includes('generateContent'))
        .map(m => m.name.replace(/^models\//, ''))

      // Prioritize flash models, then pro, then anything available
      const preferred = 
        generateModels.find(m => m.includes('2.5-flash')) ||
        generateModels.find(m => m.includes('flash') && !m.includes('thinking') && !m.includes('8b')) ||
        generateModels.find(m => m.includes('flash')) ||
        generateModels.find(m => m.includes('pro')) ||
        generateModels[0]

      if (preferred) {
        cachedModel = preferred
        console.log(`Auto-detected available Gemini model: ${preferred}`)
        return preferred
      }
    } else {
      const listErr = await listRes.text()
      console.warn(`ListModels returned status ${listRes.status}: ${listErr}`)
    }
  } catch (e) {
    console.warn('Failed to list Gemini models:', e)
  }

  // Fallback default if listing is unavailable
  return 'gemini-2.5-flash'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { messages } = await req.json()

    if (!GEMINI_API_KEY) {
      return new Response(
        JSON.stringify({ error: 'GEMINI_API_KEY not configured in Supabase secrets' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const systemPrompt = `You are a helpful and encouraging AI tutor for students. 
Your role is to:
- Explain concepts clearly and simply
- Provide step-by-step solutions
- Encourage learning through understanding, not just answers
- Be patient and supportive
- Use examples when helpful
- Break down complex topics into manageable parts

Keep responses concise (under 200 words unless a detailed explanation is requested).`

    // Format messages for Gemini API, ensuring alternating turns
    const contents: Array<{ role: string; parts: Array<{ text: string }> }> = []
    for (const msg of (messages || [])) {
      const role = msg.role === 'assistant' ? 'model' : 'user'
      const text = (msg.content || '').trim()
      if (!text) continue
      if (contents.length > 0 && contents[contents.length - 1].role === role) {
        contents[contents.length - 1].parts.push({ text })
      } else {
        contents.push({ role, parts: [{ text }] })
      }
    }

    if (contents.length === 0) {
      return new Response(
        JSON.stringify({ reply: 'Hello! How can I help you with your studies today?' }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const model = await getAvailableModel(GEMINI_API_KEY)

    // Call Gemini API
    const response = await fetch(
      `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${GEMINI_API_KEY}`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: systemPrompt }]
          },
          contents,
          generationConfig: {
            temperature: 0.7,
            topK: 40,
            topP: 0.95,
            maxOutputTokens: 1024,
          },
        }),
      }
    )

    if (!response.ok) {
      cachedModel = null // invalidate cache on failure
      const errorText = await response.text()
      console.error(`Gemini API error with model ${model} (Status ${response.status}):`, errorText)
      return new Response(
        JSON.stringify({ 
          error: `Gemini API Error (${model}): ${errorText}`,
          status: response.status 
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const data = await response.json()
    const reply = data.candidates?.[0]?.content?.parts?.[0]?.text || 
                  "I'm sorry, I couldn't generate a response. Please try again."

    return new Response(
      JSON.stringify({ reply }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in chat edge function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
