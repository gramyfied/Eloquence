-- Create confidence_scenarios table
CREATE TABLE IF NOT EXISTS public.confidence_scenarios (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    difficulty VARCHAR(50) NOT NULL CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    category VARCHAR(100) NOT NULL,
    tips TEXT[] NOT NULL DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create confidence_sessions table
CREATE TABLE IF NOT EXISTS public.confidence_sessions (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    scenario_id UUID NOT NULL REFERENCES public.confidence_scenarios(id),
    audio_file_path TEXT,
    recording_duration_seconds INTEGER NOT NULL,
    confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 1),
    fluency_score DECIMAL(3,2) CHECK (fluency_score >= 0 AND fluency_score <= 1),
    clarity_score DECIMAL(3,2) CHECK (clarity_score >= 0 AND clarity_score <= 1),
    energy_score DECIMAL(3,2) CHECK (energy_score >= 0 AND energy_score <= 1),
    overall_score DECIMAL(3,2) CHECK (overall_score >= 0 AND overall_score <= 1),
    transcription TEXT,
    improvement_suggestions TEXT[] DEFAULT '{}',
    unlocked_badges TEXT[] DEFAULT '{}',
    status VARCHAR(50) NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'abandoned')),
    started_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW()),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc', NOW())
);

-- Create indexes for better performance
CREATE INDEX idx_confidence_sessions_user_id ON public.confidence_sessions(user_id);
CREATE INDEX idx_confidence_sessions_scenario_id ON public.confidence_sessions(scenario_id);
CREATE INDEX idx_confidence_sessions_status ON public.confidence_sessions(status);
CREATE INDEX idx_confidence_sessions_started_at ON public.confidence_sessions(started_at DESC);

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = TIMEZONE('utc', NOW());
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_confidence_scenarios_updated_at BEFORE UPDATE
    ON public.confidence_scenarios FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_confidence_sessions_updated_at BEFORE UPDATE
    ON public.confidence_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default scenarios
INSERT INTO public.confidence_scenarios (title, description, difficulty, category, tips) VALUES
('Présentation personnelle', 'Présentez-vous en 30 secondes comme si vous rencontriez quelqu''un pour la première fois', 'beginner', 'social', ARRAY['Commencez par votre nom', 'Mentionnez votre passion', 'Terminez par une question']),
('Pitch d''idée', 'Présentez une idée de projet ou de business en 30 secondes', 'intermediate', 'professional', ARRAY['Soyez concis et clair', 'Mettez en avant la valeur', 'Utilisez des mots simples']),
('Motivation d''équipe', 'Motivez une équipe avant un défi important', 'advanced', 'leadership', ARRAY['Utilisez un ton énergique', 'Incluez tout le monde', 'Terminez sur une note positive']),
('Remerciement sincère', 'Exprimez votre gratitude à quelqu''un qui vous a aidé', 'beginner', 'social', ARRAY['Soyez spécifique', 'Parlez du cœur', 'Mentionnez l''impact']),
('Négociation rapide', 'Négociez un meilleur prix ou de meilleures conditions', 'intermediate', 'professional', ARRAY['Restez calme et confiant', 'Proposez du gagnant-gagnant', 'Ayez un plan B']),
('Histoire captivante', 'Racontez une anecdote personnelle intéressante', 'beginner', 'social', ARRAY['Commencez fort', 'Créez du suspense', 'Finissez avec impact']),
('Feedback constructif', 'Donnez un retour constructif à un collègue', 'intermediate', 'professional', ARRAY['Commencez par le positif', 'Soyez spécifique', 'Proposez des solutions']),
('Appel à l''action', 'Convainquez quelqu''un de passer à l''action', 'advanced', 'leadership', ARRAY['Créez l''urgence', 'Montrez les bénéfices', 'Facilitez le premier pas']),
('Excuse professionnelle', 'Présentez des excuses professionnelles pour une erreur', 'beginner', 'professional', ARRAY['Assumez la responsabilité', 'Expliquez sans justifier', 'Proposez une solution']),
('Vision inspirante', 'Partagez votre vision pour l''avenir', 'advanced', 'leadership', ARRAY['Peignez un tableau vivant', 'Connectez avec les valeurs', 'Inspirez l''action']);

-- Enable Row Level Security
ALTER TABLE public.confidence_scenarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.confidence_sessions ENABLE ROW LEVEL SECURITY;

-- Create policies for confidence_scenarios (read-only for all authenticated users)
CREATE POLICY "Users can view scenarios" ON public.confidence_scenarios
    FOR SELECT USING (auth.role() = 'authenticated');

-- Create policies for confidence_sessions
CREATE POLICY "Users can view own sessions" ON public.confidence_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create own sessions" ON public.confidence_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON public.confidence_sessions
    FOR UPDATE USING (auth.uid() = user_id);

-- Grant permissions
GRANT SELECT ON public.confidence_scenarios TO authenticated;
GRANT ALL ON public.confidence_sessions TO authenticated;