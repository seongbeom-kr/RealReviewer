REGISTER 'clean_text.py' USING jython AS myudf;

reviews = LOAD 'data/merged_data_with_university.csv'
           USING PigStorage(',')
           AS (university: chararray, store: chararray, rating: float, review_count: int, review_text: chararray, review_date: chararray, visits: int, tags: chararray);

university_reviews = FOREACH reviews GENERATE university, review_text;

cleaned_reviews = FOREACH university_reviews GENERATE university, myudf.clean_text(review_text) AS review_text;

tokenized_reviews = FOREACH cleaned_reviews GENERATE university, FLATTEN(TOKENIZE(review_text)) AS word;

grouped_words = GROUP tokenized_reviews BY (university, word);

word_counts = FOREACH grouped_words GENERATE
              FLATTEN(group) AS (university, word),
              COUNT(tokenized_reviews) AS count;

university_grouped = GROUP word_counts BY university;

top_words = FOREACH university_grouped {
    sorted_words = ORDER word_counts BY count DESC;
    top_50 = LIMIT sorted_words 50;
    GENERATE group AS university, top_50.(word, count);
};

STORE top_words INTO 'output/top_50_words_per_university' USING PigStorage(',');