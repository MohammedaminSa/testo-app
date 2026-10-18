// Supabase Edge Function: chat
// Powers the AI tutor chat. Receives the conversation, calls OpenAI, and
// returns the assistant's reply.
//
// Deploy: supabase functions deploy chat
// Set secret: supabase secrets set OPENAI_API_KEY=sk-...

import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// How many prior messages to send to the model. Keeps long chats within
// token limits while preserving recent context.
const MAX_HISTORY = 30;

const SYSTEM_PROMPT = `You are GCSE Ace, a friendly and encouraging GCSE tutor for 14-16 year old students.

Guidelines:
- Give clear, concise explanations a secondary-school student can follow.
- Use short paragraphs, bullet points, or numbered steps when helpful.
- When a topic allows it, include a small worked example.
- Stay supportive and positive; never mock a wrong answer.
- If you are unsure, say so rather than inventing facts.
- Keep most answers under 250 words unless the student asks for detail.`;

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const incoming = body.messages;

    if (!Array.isArray(incoming) || incoming.length === 0) {
      return new Response(
        JSON.stringify({ error: "messages array is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const messages = incoming
      .filter((m) => m && (m.role === "user" || m.role === "assistant") && typeof m.content === "string")
      .slice(-MAX_HISTORY)
      .map((m) => ({ role: m.role, content: m.content as string }));

    if (messages.length === 0) {
      return new Response(
        JSON.stringify({ error: "no valid messages provided" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const apiKey = Deno.env.get("OPENAI_API_KEY");
    if (!apiKey) {
      return new Response(
        JSON.stringify({ error: "OPENAI_API_KEY not configured" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const aiRes = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: SYSTEM_PROMPT },
          ...messages,
        ],
        max_tokens: 800,
        temperature: 0.7,
      }),
    });

    if (!aiRes.ok) {
      const err = await aiRes.text();
      return new Response(
        JSON.stringify({ error: `AI provider error: ${err}` }),
        { status: 502, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const data = await aiRes.json();
    const reply = data.choices?.[0]?.message?.content ?? "Sorry, I could not answer that.";

    return new Response(
      JSON.stringify({ reply }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: e.message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
